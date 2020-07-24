enum ANSIColor {
    Black
    Red
    Green
    Yellow
    Blue
    Magenta
    Cyan
    White
    BrightBlack	
    BrightRed
    BrightGreen
    BrightYellow
    BrightBlue
    BrightMagenta
    BrightCyan
    BrightWhite
}

$global:PromptConfig = @{
    ResetColors     = "`f0m"

    ForegroundColor = $( [System.Console]::ForegroundColor + 30)
    BackgroundColor = $( [System.Console]::BackgroundColor + 40)
    
    LeftArrow       = [char]0x25C4
    RightArrow      = [char]0x25BA
    History         = @{
        Enabled         = $true;
        ForegroundColor = [ANSIColor]::White.value__
        BackgroundColor = [AnsiColor]::Yellow.value__
    }

    PSDrive          = @{
        Enabled         = $true;
        ForegroundColor = [ANSIColor]::White.value__
        BackgroundColor = [ANSIColor]::Magenta.value__
    }
    PushD           = @{
        Enabled         = $true;
        ForegroundColor = [ANSIColor]::White.value__
        BackgroundColor = [ANSIColor]::BrightBlack.value__
    }
    PWD          = @{
        Enabled         = $true;
        ShowLeaf        = $false;
        ForegroundColor = [ANSIColor]::White.value__
        BackgroundColor = [ANSIColor]::Green.value__
    }
    GIT          = @{
        Enabled         = $true;

        ForegroundColor = [ANSIColor]::White.value__
        BackgroundColor = [ANSIColor]::Magenta.value__

        BranchDefaultBackgroundColor = [AnsiColor]::Magenta.value__
        BranchDefaultForegroundColor = [AnsiColor]::White.value__
        BranchWarningBackgroundColor = [AnsiColor]::Yellow.value__
        BranchWarningForegroundColor = [AnsiColor]::Yellow.value__

        
    }
    ExecutionTime   = @{
        Enabled = $true;
        ForegroundColor = [ANSIColor]::White.value__
        BackgroundColor = [AnsiColor]::BrightBlue.value__
        DefaultForegroundColor = [ANSIColor]::White.value__
        DefaultBackgroundColor = [AnsiColor]::BrightBlue.value__
        ErrorForegroundColor      = [ANSIColor]::White.value__
        ErrorBackgroundColor      = [ANSIColor]::BrightRed.value__
    }

    DateTime         = @{
        Enabled = $true;
        ForegroundColor = [ANSIColor]::White.value__
        BackgroundColor = [AnsiColor]::BrightGreen.value__
    }

    DrawArrow       = {
        param(

            [string] $Source,

            [string] $Destination,
            [Parameter(Mandatory)]
            [ValidateSet("LeftArrow", "RightArrow", "None")]
            [string] $Arrow,
            [switch] $Reset
        )
        $this = $global:PromptConfig

        if ($this.ContainsKey($Arrow))
        {
            if ($Arrow -eq "RightArrow")
            {
                # Left Side
                $ForegroundColor = if ($null -ne $this.DrawArrowLast) { $this[ $this.DrawArrowLast].BackgroundColor }
                $BackgroundColor = if (-not [String]::IsNullOrEmpty($Destination)) { $this[ $Destination].BackgroundColor }
            }
            if ($Arrow -eq "LeftArrow")
            {
                # Right Side
                $ForegroundColor = if (-not [String]::IsNullOrEmpty($Destination)) { $this[ $Destination].BackgroundColor }
                $BackgroundColor = if ($null -ne $this.DrawArrowLast) { $this[ $this.DrawArrowLast].BackgroundColor }
            }
            # Draw the Arrows
            . {
                "`f0m"
                if (![string]::IsNullOrEmpty($BackgroundColor))
                {
                    "`f48;5;{0}m" -f $BackgroundColor
                }
                if ($ForegroundColor) {
                    "`f38;5;{0}m" -f $ForegroundColor
                }
                $this[$Arrow]
            }
            $Result
        }

        # Sets Base Foreground and Background Color. So you dont have to.
        "`f0m`f48;5;{0}m`f38;5;{1}m" -f $this[ $Destination ].BackgroundColor, $this[ $Destination ].ForegroundColor

        if ($Reset)
        {
            $this.DrawArrowLast = $null;
        }
        else {
            $this.DrawArrowLast = $Destination
        }
    }
    DrawArrowLast   = $null
}

[System.Collections.Generic.List[ScriptBlock]]$global:PromptRight = @(
    # right aligned
    # ExecutionTime
    {
        $this = $global:PromptConfig["ExecutionTime"]
        if ($true -eq $this.Enabled)
        {
            # Color should change if an error was thrown
            if ($global:PromptConfig.HasError) {
                $this.ForegroundColor = $this.DefaultForegroundColor
                $this.BackgroundColor = $this.DefaultBackgroundColor
            }
            else
            {
                $this.ForegroundColor = $this.ErrorForegroundColor
                $this.BackgroundColor = $this.ErrorBackgroundColor
            }

            . $global:PromptConfig.DrawArrow -Arrow LeftArrow -Destination "ExecutionTime"
            #"{0:d4}" -f $MyInvocation.HistoryID
            "{0}" -f $(
                if (@(get-history).Count -gt 0) {
                    (get-history)[-1] | 
                        ForEach-Object {
                            "{0:c}" -f (new-timespan $_.StartExecutionTime $_.EndExecutionTime)
                        }
                }
                else
                {
                    '00:00:00.0000000'

                }
            )
        }
    }
    # DateTime
    {
        $this = $global:PromptConfig["DateTime"]
        if ($true -eq $this.Enabled)
        {
            . $global:PromptConfig.DrawArrow -Arrow LeftArrow -Destination "DateTime"
            $(Get-Date -Format "hh:mm:ss tt")
        }
    }
)

[System.Collections.Generic.List[ScriptBlock]]$global:PromptLeft = @(
    # History
    { 
        $this = $global:PromptConfig["History"]
        if ($true -eq $this.Enabled)
        {
            . $global:PromptConfig.DrawArrow -Arrow None -Destination "History"
            "{0:d4}" -f $MyInvocation.HistoryID
        }
    }

    {
        $this = $global:PromptConfig["PushD"]
        if ($true -eq $this.Enabled)
        {
            . $global:PromptConfig.DrawArrow -Arrow RightArrow -Destination "PushD"
            if ($pushd = (Get-Location -Stack).count) { "$([char]187)" + $pushd }
            else {
                " 0 "
            }
        }
    }

    # PSDrive
    {
        $this = $global:PromptConfig["PSDrive"]
        if ($true -eq $this.Enabled)
        {
            . $global:PromptConfig.DrawArrow -Arrow LeftArrow -Destination "PSDrive"
            " "
            $pwd.Drive.Name
            ":"
        }

    }

    # PWD
    {
        $this = $global:PromptConfig["PWD"]
        if ($true -eq $this.Enabled)
        {
            . $global:PromptConfig.DrawArrow -Arrow RightArrow -Destination "PWD"

            if ($this.ShowLeaf) {
                Split-Path $pwd -leaf
            }
            else {
                $pwd.path.Replace($pwd.Drive.Root, "")
            }
        }
    }
    
    # GIT
    {
        $this = $global:PromptConfig["GIT"]
        if ($true -eq $this.Enabled)
        {
            $branch = git symbolic-ref --short -q HEAD
            $aheadbehind = git status -sb
            $distance = ''

            # Set Color based off of Alert.
            $this.BackgroundColor = $this.BranchDefaultBackgroundColor
            $this.ForegroundColor = $this.BranchDefaultForegroundColor
            if (-not [string]::IsNullOrEmpty($(git diff --staged))) {
                $this.BackgroundColor = $this.BranchWarningBackgroundColor
                $this.ForegroundColor = $this.BranchWarningForegroundColor
            }

            . $global:PromptConfig.DrawArrow -Arrow RightArrow -Destination "GIT"
            $branch

            if ($aheadbehind -match '\[\w+.*\w+\]$')
            {
                $ahead = [regex]::matches($aheadbehind, '(?<=ahead\s)\d+').value
                $behind = [regex]::matches($aheadbehind, '(?<=behind\s)\d+').value

                $distance = ""
                if ($ahead) { $distance += "a$ahead" }
                if ($behind) { $distance += "b$behind" }

                . $global:PromptConfig.DrawArrow -Arrow "None" -Destination "GIT"
                Write-Host $distance
            }

            . $global:PromptConfig.DrawArrow -Arrow RightArrow -Reset
        }
    }
)

function global:prompt {
    $global:PromptConfig.HasError = $?
	$gitTest = $(git config -l) -match 'branch\.'
    if (-not [string]::IsNullOrEmpty($gitTest))
    {
        $leftSide = -join @($global:PromptLeft + {" "}).Invoke()
    }
    else
    {
        return "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) ";
    }

    $rightSide = -join ($global:PromptRight).Invoke()
    $offset = $global:host.UI.RawUI.BufferSize.Width - 28

    $prompt = -join @($leftSide, "`f${offset}G", $rightSide, "`f0m" + "`n`r`> ")
    $prompt -Replace "`f", "$([char]27)["
}

# Set this alias every time PowerShell launches so I stop mistyping code-insiders
Set-Alias code code-insiders

Set-PSReadLineOption -PredictionSource History
