# create self-signed root certificate
$cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
-Subject "CN=P2SRootCert" -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign

# create a client certificate signed by the root certificate
$childCert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
-Subject "CN=device@p2s.org" -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" `
-Signer $cert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")

# export self-signed root certificate in base64 encoding x.509 (.cer) to the current directory
$cer = $cert | Export-Certificate -Type CERT -FilePath "$((Get-Location).Path)\P2SRootCert.cer"
certutil -encode $cer P2SRootCert.b64 && del $cer
# need to remove the first line "-----BEGIN CERTIFICATE-----" and the last line "-----END CERTIFICATE-----" of the base64 encoded certificate file using powershell
(Get-Content P2SRootCert.b64) | Select-Object -Skip 1 | Select-Object -SkipLast 1 | Set-Content P2SRootCert.b64

# export client certificate in PKCS #12 encoding (.PFX) to the current directory
# you will be prompted for a password to protect the certificate
$pwd = Read-Host -AsSecureString -Prompt "Enter password to protect the P2SChildCert.pfx file: "
# keep going with the script and enter the password when prompted
$childCert | Export-PfxCertificate -FilePath "$((Get-Location).Path)\P2SChildCert.pfx" -Password $pwd