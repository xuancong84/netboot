mount -t ecryptfs home home -o rw,ecryptfs_cipher=aes,ecryptfs_key_bytes=32,ecryptfs_passthrough=no,ecryptfs_enable_filename_crypto=yes,ecryptfs_sig=$(cat /root/.ecryptfs/sig-cache.txt)
