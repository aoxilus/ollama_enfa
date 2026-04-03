param (
    [int]$N
)

if ($N -lt 0) {
    exit 1
}

$factorial = 1
for ($i = 1; $i -le $N; $i++) {
    $factorial *= $i
}

Write-Output $factorial