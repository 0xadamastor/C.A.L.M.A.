#!/bin/bash

echo "A configurar Cuckoo Sandbox para CALMA..."

mkdir -p ~/.cuckoo/conf

cat > ~/.cuckoo/conf/cuckoo.conf << 'EOF'
[cuckoo]
machinery = virtualbox
analysis_timeout = 300
critical_timeout = 200
delete_original = no
memory_dump = no
