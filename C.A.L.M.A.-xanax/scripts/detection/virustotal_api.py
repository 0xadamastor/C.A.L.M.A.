"""
API VirusTotal Integration Module
Integração com sandbox do VirusTotal para análise profissional de ficheiros
"""

import os
import json
import hashlib
import time
from pathlib import Path
from dataclasses import dataclass
from typing import Optional, Dict, Tuple
import requests

# Configuração
VT_API_BASE = "https://www.virustotal.com/api/v3"
VT_FILE_SCAN_ENDPOINT = f"{VT_API_BASE}/files"
VT_ANALYSIS_ENDPOINT = f"{VT_API_BASE}/analyses"
VT_HASH_LOOKUP_ENDPOINT = f"{VT_API_BASE}/files"

# Timeouts e retries
MAX_RETRIES = 3
RETRY_DELAY = 2
ANALYSIS_TIMEOUT = 300  # 5 minutos


@dataclass
class VTDetectionResult:
    """Resultado de análise do VirusTotal"""
    file_hash: str
    file_path: str
    file_size: int
    analysis_id: Optional[str]
    is_malicious: bool
    threat_name: Optional[str]
    malicious_count: int
    undetected_count: int
    total_vendors: int
    vendors_detected: Dict[str, str]
    analysis_date: Optional[str]
    error: Optional[str]
    
    def __str__(self) -> str:
        if self.error:
            return f"Erro VirusTotal: {self.error}"
        
        status_tag = "[!]" if self.is_malicious else "[OK]"
        status = "MALWARE" if self.is_malicious else "LIMPO"
        
        return f"""
╔══════════════════════════════════════════════════════════╗
║            ANALISE VIRUSTOTAL (SANDBOX)                  ║
╠══════════════════════════════════════════════════════════╣
║ {status_tag} RESULTADO: {status:<40} ║
╠══════════════════════════════════════════════════════════╣
║ Hash SHA256:    {self.file_hash[:44]:<43} ║
║ Tamanho:        {self._format_size():<43} ║
║ Data Análise:   {str(self.analysis_date):<43} ║
║                                                          ║
║ DETECÇÕES:      {self.malicious_count}/{self.total_vendors} Antivírus                 ║
║ Limpo:          {self.undetected_count}/{self.total_vendors} Antivírus                 ║
║                                                          ║
║ Vendors detectados:                                      ║
{self._format_vendors()}
╚══════════════════════════════════════════════════════════╝
"""
    
    def _format_size(self) -> str:
        """Formata o tamanho do ficheiro"""
        size = self.file_size
        for unit in ['B', 'KB', 'MB', 'GB']:
            if size < 1024:
                return f"{size:.1f} {unit}"
            size /= 1024
        return f"{size:.1f} TB"
    
    def _format_vendors(self) -> str:
        """Formata a lista de vendors com detecções"""
        if not self.vendors_detected:
            return "║ (Nenhum antivírus detectou ameaça)               ║"
        
        lines = []
        for vendor, threat in list(self.vendors_detected.items())[:5]:
            threat_short = threat[:33] if threat else "Unknown"
            lines.append(f"║   • {vendor:<15} {threat_short:<28} ║")
        
        if len(self.vendors_detected) > 5:
            remaining = len(self.vendors_detected) - 5
            lines.append(f"║   • +{remaining} antivírus adicionais                  ║")
        
        return "\n".join(lines) if lines else "║ (Nenhum antivírus detectou ameaça)               ║"


class VirusTotalAPI:
    """Cliente para API do VirusTotal"""
    
    def __init__(self, api_key: str):
        """
        Inicializa cliente VirusTotal
        
        Args:
            api_key: Chave API do VirusTotal
        """
        if not api_key or api_key == "YOUR_VIRUSTOTAL_API_KEY":
            raise ValueError(
                "API key do VirusTotal não configurada!\n"
                "Faça login em https://www.virustotal.com/ e adicione a chave em config/calma_config.json\n"
                "Campo: 'virustotal_api_key'"
            )
        
        self.api_key = api_key
        self.session = requests.Session()
        self.session.headers.update({
            'x-apikey': api_key,
            'User-Agent': 'CALMA-Malware-Detection/1.0'
        })
    
    def _calculate_file_hash(self, file_path: str, algorithm: str = 'sha256') -> str:
        """Calcula hash do ficheiro"""
        hash_obj = hashlib.new(algorithm)
        
        with open(file_path, 'rb') as f:
            for chunk in iter(lambda: f.read(8192), b''):
                hash_obj.update(chunk)
        
        return hash_obj.hexdigest()
    
    def check_hash(self, file_hash: str) -> Optional[VTDetectionResult]:
        """
        Verifica se um hash já foi analisado no VirusTotal
        
        Args:
            file_hash: SHA256 hash do ficheiro
            
        Returns:
            VTDetectionResult se encontrado, None caso contrário
        """
        try:
            url = f"{VT_HASH_LOOKUP_ENDPOINT}/{file_hash}"
            response = self.session.get(url, timeout=30)
            
            if response.status_code == 404:
                return None
            
            response.raise_for_status()
            data = response.json()
            
            return self._parse_analysis_response(data, file_hash, "")
            
        except requests.exceptions.RequestException as e:
            return VTDetectionResult(
                file_hash=file_hash,
                file_path="",
                file_size=0,
                analysis_id=None,
                is_malicious=False,
                threat_name=None,
                malicious_count=0,
                undetected_count=0,
                total_vendors=0,
                vendors_detected={},
                analysis_date=None,
                error=f"Erro ao consultar hash: {str(e)}"
            )
    
    def scan_file(self, file_path: str) -> Tuple[str, Optional[VTDetectionResult]]:
        """
        Envia ficheiro para análise no VirusTotal
        
        Args:
            file_path: Caminho para o ficheiro
            
        Returns:
            Tuple (analysis_id, result)
        """
        file_path = Path(file_path)
        
        if not file_path.exists():
            raise FileNotFoundError(f"Ficheiro não encontrado: {file_path}")
        
        if file_path.stat().st_size > 650 * 1024 * 1024:  # 650MB limit
            raise ValueError(f"Ficheiro muito grande: {file_path.stat().st_size / (1024*1024):.1f}MB (máx 650MB)")
        
        # Calcula hash para verificação prévia
        file_hash = self._calculate_file_hash(str(file_path))
        
        # Tenta verificar se já foi analisado
        print(f"[VirusTotal] Verificando se o ficheiro já foi analisado...")
        existing_result = self.check_hash(file_hash)
        
        if existing_result and not existing_result.error:
            print(f"[VirusTotal] Ficheiro encontrado na base de dados (análise anterior)")
            return file_hash, existing_result
        
        # Envia para análise
        print(f"[VirusTotal] Enviando ficheiro para análise na sandbox ({file_path.stat().st_size / (1024*1024):.1f}MB)...")
        
        try:
            with open(file_path, 'rb') as f:
                files = {'file': (file_path.name, f)}
                response = self.session.post(
                    VT_FILE_SCAN_ENDPOINT,
                    files=files,
                    timeout=120
                )
            
            response.raise_for_status()
            data = response.json()
            analysis_id = data['data']['id']
            
            print(f"[VirusTotal] Ficheiro enviado (ID: {analysis_id})")
            print(f"[VirusTotal] Aguardando resultado da análise...")
            
            # Aguarda resultado
            result = self._wait_for_analysis(analysis_id, file_path, file_hash)
            return file_hash, result
            
        except requests.exceptions.RequestException as e:
            return file_hash, VTDetectionResult(
                file_hash=file_hash,
                file_path=str(file_path),
                file_size=file_path.stat().st_size,
                analysis_id=None,
                is_malicious=False,
                threat_name=None,
                malicious_count=0,
                undetected_count=0,
                total_vendors=0,
                vendors_detected={},
                analysis_date=None,
                error=f"Erro ao enviar ficheiro: {str(e)}"
            )
    
    def _wait_for_analysis(self, analysis_id: str, file_path: Path, file_hash: str, timeout: int = ANALYSIS_TIMEOUT) -> VTDetectionResult:
        """
        Aguarda pela conclusão da análise
        
        Args:
            analysis_id: ID da análise do VirusTotal
            file_path: Caminho do ficheiro (para informação)
            file_hash: Hash do ficheiro
            timeout: Timeout em segundos
            
        Returns:
            VTDetectionResult
        """
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            try:
                url = f"{VT_ANALYSIS_ENDPOINT}/{analysis_id}"
                response = self.session.get(url, timeout=30)
                response.raise_for_status()
                
                data = response.json()
                status = data['data']['attributes']['status']
                
                if status == 'completed':
                    print(f"[VirusTotal] Análise concluída!")
                    return self._parse_analysis_response(data, file_hash, str(file_path))
                
                elif status == 'queued':
                    elapsed = int(time.time() - start_time)
                    print(f"[VirusTotal] Em fila... ({elapsed}s)")
                    time.sleep(5)
                
                elif status == 'running':
                    elapsed = int(time.time() - start_time)
                    print(f"[VirusTotal] Analisando... ({elapsed}s)")
                    time.sleep(10)
                
                else:
                    return VTDetectionResult(
                        file_hash=file_hash,
                        file_path=str(file_path),
                        file_size=file_path.stat().st_size,
                        analysis_id=analysis_id,
                        is_malicious=False,
                        threat_name=None,
                        malicious_count=0,
                        undetected_count=0,
                        total_vendors=0,
                        vendors_detected={},
                        analysis_date=None,
                        error=f"Estado desconhecido: {status}"
                    )
            
            except requests.exceptions.RequestException as e:
                print(f"[VirusTotal] Erro ao consultar status: {e}")
                time.sleep(5)
        
        return VTDetectionResult(
            file_hash=file_hash,
            file_path=str(file_path),
            file_size=file_path.stat().st_size,
            analysis_id=analysis_id,
            is_malicious=False,
            threat_name=None,
            malicious_count=0,
            undetected_count=0,
            total_vendors=0,
            vendors_detected={},
            analysis_date=None,
            error=f"Timeout na análise (>{timeout}s)"
        )
    
    def _parse_analysis_response(self, data: Dict, file_hash: str, file_path: str) -> VTDetectionResult:
        """
        Parse da resposta da API do VirusTotal
        
        Args:
            data: Response JSON do VirusTotal
            file_hash: Hash do ficheiro
            file_path: Caminho do ficheiro
            
        Returns:
            VTDetectionResult
        """
        try:
            attributes = data['data']['attributes']
            stats = attributes.get('last_analysis_stats', {})
            results = attributes.get('last_analysis_results', {})
            
            malicious_count = stats.get('malicious', 0)
            undetected_count = stats.get('undetected', 0)
            total_vendors = sum(stats.values())
            
            # Extrai vendors que detectaram
            vendors_detected = {}
            for vendor, result in results.items():
                if result.get('category') == 'malicious':
                    vendors_detected[vendor] = result.get('engine_name', 'Unknown')
            
            is_malicious = malicious_count > 0
            threat_name = None
            
            if is_malicious and vendors_detected:
                # Usa o primeiro vendor como nome da ameaça
                threat_name = list(vendors_detected.values())[0]
            
            analysis_date = attributes.get('last_analysis_date')
            
            file_size = 0
            if file_path:
                try:
                    file_size = Path(file_path).stat().st_size
                except:
                    pass
            
            return VTDetectionResult(
                file_hash=file_hash,
                file_path=file_path,
                file_size=file_size,
                analysis_id=data['data']['id'],
                is_malicious=is_malicious,
                threat_name=threat_name,
                malicious_count=malicious_count,
                undetected_count=undetected_count,
                total_vendors=total_vendors,
                vendors_detected=vendors_detected,
                analysis_date=str(analysis_date) if analysis_date else None,
                error=None
            )
        
        except Exception as e:
            return VTDetectionResult(
                file_hash=file_hash,
                file_path=file_path,
                file_size=0,
                analysis_id=None,
                is_malicious=False,
                threat_name=None,
                malicious_count=0,
                undetected_count=0,
                total_vendors=0,
                vendors_detected={},
                analysis_date=None,
                error=f"Erro ao processar resposta: {str(e)}"
            )


def get_virustotal_client(config_file: str = None) -> VirusTotalAPI:
    """
    Factory para obter cliente VirusTotal a partir do ficheiro de config
    
    Args:
        config_file: Caminho para config (default: config/calma_config.json)
        
    Returns:
        VirusTotalAPI client
    """
    if config_file is None:
        config_file = Path(__file__).parent.parent.parent / "config" / "calma_config.json"
    
    if not Path(config_file).exists():
        raise FileNotFoundError(f"Ficheiro de configuração não encontrado: {config_file}")
    
    with open(config_file) as f:
        config = json.load(f)
    
    api_key = config.get('virustotal_api_key')
    if not api_key:
        raise ValueError(
            "virustotal_api_key não configurada em config/calma_config.json\n"
            "Obtenha uma chave em: https://www.virustotal.com/gui/home/upload"
        )
    
    return VirusTotalAPI(api_key)


if __name__ == '__main__':
    import sys
    
    if len(sys.argv) < 2:
        print("Uso: python virustotal_api.py <caminho_ficheiro>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    
    try:
        client = get_virustotal_client()
        file_hash, result = client.scan_file(file_path)
        print(result)
    except Exception as e:
        print(f"[ERRO] {e}")
        sys.exit(1)
