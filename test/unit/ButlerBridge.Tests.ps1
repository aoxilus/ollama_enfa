BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
    $script:StubExe = Join-Path $RepoRoot "test\fixtures\stub_butler_client.cmd"
    $script:BridgePath = Join-Path $RepoRoot "powershell\ButlerCppBridge.ps1"
    . $script:BridgePath
}

Describe "ButlerCppBridge" {
    BeforeEach {
        $script:OldClient = $env:BUTLER_CPP_CLIENT
        $env:BUTLER_CPP_CLIENT = $script:StubExe
    }
    AfterEach {
        $env:BUTLER_CPP_CLIENT = $script:OldClient
    }

    It "resolves stub via BUTLER_CPP_CLIENT" {
        $p = Get-ButlerCppExecutable
        $p | Should -Not -BeNullOrEmpty
        (Test-Path -LiteralPath $p) | Should -Be $true
    }

    It "Invoke-ButlerCppInvoke ask returns stub stdout" {
        $r = Invoke-ButlerCppInvoke -Prompt "ping" -MaxTokens 10 -Temperature 0 -TimeoutSec 5
        $r.Text.Trim() | Should -Be "STUB_OK"
    }

    It "Invoke-ButlerCppInvoke fast returns STUB_FAST" {
        $r = Invoke-ButlerCppInvoke -Prompt "x" -MaxTokens 10 -Temperature 0.1 -TimeoutSec 5 -ChatFast
        $r.Text.Trim() | Should -Be "STUB_FAST"
    }
}
