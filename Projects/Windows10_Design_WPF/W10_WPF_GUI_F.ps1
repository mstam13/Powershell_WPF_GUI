[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | out-null
[System.Reflection.Assembly]::LoadFrom('assembly\MahApps.Metro.dll')       | out-null
[System.Reflection.Assembly]::LoadFrom('assembly\System.Windows.Interactivity.dll') | out-null

########################################################################################################################################################################################################	
#*******************************************************************************************************************************************************************************************************
#																						 PROGRESSBAR DESIGN 
#*******************************************************************************************************************************************************************************************************
########################################################################################################################################################################################################

$syncProgress = [hashtable]::Synchronized(@{})
$childRunspace =[runspacefactory]::CreateRunspace()
$childRunspace.ApartmentState = "STA"
$childRunspace.ThreadOptions = "ReuseThread"         
$childRunspace.Open()
$childRunspace.SessionStateProxy.SetVariable("syncProgress",$syncProgress)          
$PsChildCmd = [PowerShell]::Create().AddScript({   
    [xml]$xaml = @"
	<Window
	xmlns:Controls="clr-namespace:MahApps.Metro.Controls;assembly=MahApps.Metro"
	xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
	xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
	x:Name="WindowSplash" Title="SplashScreen" WindowStyle="None" WindowStartupLocation="CenterScreen"
	Background="#FF006099" ShowInTaskbar ="true" 
	Width="900" Height="650" ResizeMode = "NoResize" >
	
	 <Grid HorizontalAlignment="Center" VerticalAlignment="Center">	
 <StackPanel Orientation="Vertical" HorizontalAlignment="Center" Margin="0,15,0,0">	
		<StackPanel Orientation="Vertical" HorizontalAlignment="Center" Margin="0,15,0,0">	
			<Controls:ProgressRing x:Name="Deployment_Progressbar" IsActive="True" Margin="0,0,0,0" Foreground="White" Width="60"/>			
			
			<Label x:Name="Step_Status_Label" Margin="0,60,0,0" Foreground="White" FontSize="24" Content="Configuing update for Windows 10"> </Label>
			<Label x:Name="Step_Status" Margin="0,0,0,0" HorizontalAlignment="Center" FontSize="24" Foreground="White"> </Label>
			</StackPanel>
			
		<StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,0">
		  <Label x:Name="Progress_Status"  Margin="0,5,0,0"  FontSize="24" Foreground="White" HorizontalAlignment="Center"></Label>
		</StackPanel>
		 <Label x:Name="Progress_Status_Label2"  FontSize="24" Content="Do not turn off your fake Windows 10..." Margin="0,160,0,0" Foreground="White" HorizontalAlignment="Center"></Label>
		</StackPanel>
	</Grid>

		
</Window> 
"@
  
    $reader=(New-Object System.Xml.XmlNodeReader $xaml)
    $syncProgress.Window=[Windows.Markup.XamlReader]::Load($reader)
    $syncProgress.ProgressRing = $syncProgress.window.FindName("Deployment_Progressbar")
    $syncProgress.Label2 = $syncProgress.window.FindName("Step_Status")
    $syncProgress.Label = $syncProgress.window.FindName("Progress_Status")       
    $syncProgress.Window.ShowDialog() | Out-Null
    $syncProgress.Error = $Error



})


#########################################################################################################################################################################################################	
#*******************************************************************************************************************************************************************************************************
#																			FUNCTIONS
#*******************************************************************************************************************************************************************************************************
#########################################################################################################################################################################################################	

$Global:Total_Step = "40"

################ Launch Progress Bar  ########################  
Function Launch_modal_progress{    
    $PsChildCmd.Runspace = $childRunspace
    $Script:Childproc = $PsChildCmd.BeginInvoke()
}

################ Update Progress Bar  ########################  
Function Update_progressBar {
    param(
    [String]$script:Step_Name,
    [String]$script:Step_Status		
    )
        $syncProgress.ProgressRing.Dispatcher.Invoke("Normal",[action]{	
        $syncProgress.Label.Content=$script:Step_Name
        $syncProgress.Label2.Content=$script:Step_Status			
    })
}

################ Close Progress Bar  ########################  
Function Close_modal_progress{
    $syncProgress.Window.Dispatcher.Invoke([action]{$syncProgress.Window.close()})
    $PsChildCmd.EndInvoke($Script:Childproc) | Out-Null
    $childRunspace.Close() | Out-Null 
}

$Previous_Step = " " 
Launch_modal_progress
sleep 1

$Current_Step_Number=1

Do
	{			
        $Current_Step_Number++

		If ($Previous_Step -ne $Next_Step)
			{
				$Current_Step_Total = $Current_Step_Number / $Total_Step * 100 
				$Round_Current_Step_Total = [math]::Round($Current_Step_Total)
				$Percent_Complete = "$Round_Current_Step_Total %" 
				Update_progressBar "$Percent_Complete complete" "Install  the update $Current_Step_Number of $Total_Step "							
			}		
  }
        
       
until ($Current_Step_Number -eq $Global:Total_Step) 
sleep 3
Close_modal_progress


