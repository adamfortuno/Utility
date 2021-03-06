function md5_hash ([string]$file_path) {
    $file_contents = New-Object System.IO.FileStream($file_path, [System.IO.FileMode]::Open)
    $hash = [System.Security.Cryptography.HashAlgorithm]::Create("MD5")
    $check_sum = New-Object System.Text.StringBuilder

    $hash.ComputeHash($file_contents) | % { [void] $check_sum.Append($_.ToString("x2")) }
     
    $file_contents.Dispose()
    $check_sum.ToString()
}

md5_hash($args[0])
