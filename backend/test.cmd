rem Upload file via PowerShell

powershell.exe -Command "$wc = New-Object System.Net.WebClient;$wc.Headers.Add('X-AuthKey','abcd1234');$wc.UploadFile('http://localhost:8000/upload.php','..\README.md')"

@pause
