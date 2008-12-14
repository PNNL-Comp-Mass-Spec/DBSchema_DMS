Option Strict On

' Written by Matthew Monroe for PNNL
'
' Last modified December 13, 2008

Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Data.SqlTypes
Imports Microsoft.SqlServer.Server


Partial Public Class StoredProcedures
    ''' <summary>
    ''' Looks for the newest subfolder matching the given analysis job in the specified parent folder
    ''' If found, then looks for files AnalysisSummary.txt and DataExtractionSummary.txt and updates
    '''  AnalysisManagerIsDone and DataExtractionIsDone if the files exist and if they were modified over JobCompleteHoldoffMinutes minutes ago
    ''' </summary>
    <Microsoft.SqlServer.Server.SqlProcedure()> _
    Public Shared Sub ValidateAnalysisJobResultsFolder(ByVal Job As SqlInt32, _
                                                      ByVal JobCompleteHoldoffMinutes As SqlInt32, _
                                                      <Runtime.InteropServices.Out()> ByRef AnalysisManagerIsDone As SqlByte, _
                                                      <Runtime.InteropServices.Out()> ByRef DataExtractionIsDone As SqlByte, _
                                                      <Runtime.InteropServices.Out()> ByRef ResultsFolderName As SqlString, _
                                                      <Runtime.InteropServices.Out()> ByRef ResultsFolderPath As SqlString, _
                                                      <Runtime.InteropServices.Out()> ByRef ResultsFolderTimestamp As SqlDateTime, _
                                                      <Runtime.InteropServices.Out()> ByRef OrganismDBName As SqlString, _
                                                      <Runtime.InteropServices.Out()> ByRef Message As SqlString, _
                                                      <Runtime.InteropServices.Out()> ByRef InfoOnly As SqlByte)

        ' This procedure looks for the given job in T_Analysis_Job
        ' If found, it uses the dataset for the job to construct the path to the transfer folder (based on the processor for the job, or the dataset if a Job_Broker job)
        ' Next, the a matching result folder is looked for.  If found, the newest folder is chosen and then it is examined
        '  to look for file AnalysisSummary.txt
        ' If this file exists, then it's modification time is examined.  If modified more than JobCompleteHoldoffMinutes minutes ago, 
        '  then AnalysisManagerIsDone is set to 1.  Otherwise, AnalysisManagerIsDone is set to 0 and the procedure exits
        ' Next, the AnalysisSummary.txt file is parsed to look for the line starting with "Fasta File Name"; if found, then parameter OrganismDBName is updated with that line's contents
        ' Lastly, thep procedure looks for file DataExtractionSummary.txt; if found, then also checks for a _syn.txt file
        '  If both DataExtractionSummary.txt and the _syn.txt file are found, then DataExtractionIsDone is set to 1
        '
        ' If InfoOnly is non-zero, then debugging statements are shown


        Const ANALYSIS_SUMMARY_FILE As String = "AnalysisSummary.txt"
        Const DEX_SUMMARY_FILE As String = "DataExtractionSummary.txt"
        Const SYN_FILE_SUFFIX As String = "_syn.txt"

        Const ORGANISM_DB_NAME_LINE_HEADER As String = "Fasta File Name"


        Dim cnConnection As System.Data.SqlClient.SqlConnection
        Dim cmdJobInfo As System.Data.SqlClient.SqlCommand
        Dim objReader As System.Data.SqlClient.SqlDataReader

        Dim strVolNameClient As String
        Dim strAssignedProcessor As String
        Dim strResultsFolderNameFromDB As String
        Dim strDataset As String

        Dim strSql As String

        Dim objTransferFolderInfo As System.IO.DirectoryInfo
        Dim objResultsFolders() As System.IO.DirectoryInfo
        Dim objSubFolder As System.IO.DirectoryInfo

        Dim objResultsFolderInfo As System.IO.DirectoryInfo
        Dim objAnalysisSummaryFiles() As System.IO.FileInfo

        Dim objFileInfo As System.IO.FileInfo

        Dim objResultsFolderForJob As System.IO.DirectoryInfo
        Dim objFiles() As System.IO.FileInfo

        Dim intSubfolderCount As Integer
        Dim strSubFolderNames() As String
        Dim dtSubFolderDates() As DateTime

        Dim strTransferFolderPath As String = String.Empty
        Dim strResultsFolderPath As String = String.Empty
        Dim strAnalysisSummaryPath As String = String.Empty
        Dim strDEXSummaryPath As String = String.Empty

        Dim blnJobBrokerInUse As Boolean = False
        Dim blnTransferFolderExists As Boolean = False
        Dim blnResultsFolderExists As Boolean = False

        Dim tsInFile As System.IO.StreamReader
        Dim strLineIn As String
        Dim strFastaFileName As String = String.Empty

        ' Validate the inputs
        If Job.IsNull Then
            Message = "Error: Job parameter is null"
            Exit Sub
        End If

        If JobCompleteHoldoffMinutes.IsNull Then
            JobCompleteHoldoffMinutes = 10
        End If

        If InfoOnly.IsNull Then
            InfoOnly = 0
        End If

        ' Clear the output parameters
        AnalysisManagerIsDone = 0
        DataExtractionIsDone = 0
        ResultsFolderName = String.Empty
        ResultsFolderPath = String.Empty
        ResultsFolderTimestamp = #1/1/1980#
        OrganismDBName = ""
        Message = ""


        ' Determine the analysis tool and transfer folder for this job
        Try
            cnConnection = New System.Data.SqlClient.SqlConnection("context connection=true")
            cnConnection.Open()

            strSql = " SELECT IsNull(SPath.SP_vol_name_client, ''), " & _
                            " IsNull(AJ.AJ_assignedProcessorName, ''), " & _
                            " IsNull(AJ.AJ_resultsFolderName, ''), " & _
                            " DS.Dataset_Num" & _
                     " FROM dbo.T_Analysis_Job AJ INNER JOIN " & _
                     " dbo.T_Dataset DS ON AJ.AJ_datasetID = DS.Dataset_ID INNER JOIN " & _
                     " dbo.t_storage_path SPath ON DS.DS_storage_path_ID = SPath.SP_path_ID " & _
                     " WHERE(AJ.AJ_jobID = " & Job.ToString & ")"

            cmdJobInfo = New System.Data.SqlClient.SqlCommand(strSql, cnConnection)

            objReader = cmdJobInfo.ExecuteReader()

            ' Use the following command to redirect the results of the query to the calling procedure (and thus display them to the user)
            ' SqlContext.Pipe.Send(objReader)

            If objReader.Read Then
                strVolNameClient = objReader.GetString(0)
                strAssignedProcessor = objReader.GetString(1)
                strResultsFolderNameFromDB = objReader.GetString(2)
                strDataset = objReader.GetString(3)

                If strVolNameClient Is Nothing Then strVolNameClient = "?"
                If strAssignedProcessor Is Nothing Then strAssignedProcessor = "?"
                If strResultsFolderNameFromDB Is Nothing Then strResultsFolderNameFromDB = "?"
                If strDataset Is Nothing Then strDataset = "?"

            Else
                Message = "Error: Could not find job " & Job.ToString & " in T_Analysis_Job"
                Exit Sub
            End If

            Try
                If strVolNameClient.Length = 0 Then
                    Message = "Error: Job " & Job.ToString & " has an undefined value for SP_vol_name_client for the job's dataset"
                    Exit Sub
                ElseIf strAssignedProcessor.Length = 0 Then
                    Message = "Error: Job " & Job.ToString & " does not have a defined processor in T_Analysis_Job"
                    Exit Sub
                Else
                    If strAssignedProcessor.ToLower = "job_broker" Then
                        ' Job Broker job
                        ' Transfer folder is of the form \\proto-3\DMS3_XFER\DatasetName\
                        strTransferFolderPath = System.IO.Path.Combine(strVolNameClient, "DMS3_Xfer")
                        strTransferFolderPath = System.IO.Path.Combine(strTransferFolderPath, strDataset)
                        blnJobBrokerInUse = True
                    Else
                        strTransferFolderPath = System.IO.Path.Combine(strVolNameClient, "DMS3_Xfer")
                        strTransferFolderPath = System.IO.Path.Combine(strTransferFolderPath, strAssignedProcessor)
                        blnJobBrokerInUse = False
                    End If
                    Message = "Transfer folder: " & strTransferFolderPath
                End If

                If InfoOnly <> 0 Then
                    SqlContext.Pipe.Send(CStr(Message))
                End If

            Catch ex As Exception
                Message = "Error building transfer folder path using T_Analysis_Job for Job " & Job.ToString
            End Try

        Catch ex As Exception
            Message = "Error opening database connection: " & ex.Message
            Exit Sub
        End Try

        ' Check for the existence of the results folder on the storage server
        Try
            ' First look for the transfer folder
            blnTransferFolderExists = System.IO.Directory.Exists(strTransferFolderPath)
        Catch ex As Exception
            Message = "Error: Exception looking for transfer folder: " & ex.Message
            Exit Sub
        End Try

        If Not blnTransferFolderExists Then
            If blnJobBrokerInUse Then
                Message = "Warning: Dataset transfer folder does not yet exist: " & strTransferFolderPath
            Else
                Message = "Error: Transfer folder not found: " & strTransferFolderPath
            End If

            If InfoOnly <> 0 Then
                SqlContext.Pipe.Send(CStr(Message))
            End If
        Else
            Try
                objTransferFolderInfo = New System.IO.DirectoryInfo(strTransferFolderPath)

                objResultsFolders = objTransferFolderInfo.GetDirectories("*" & Job.ToString)

                If objResultsFolders.Length > 0 Then
                    ReDim strSubFolderNames(objResultsFolders.Length - 1)
                    ReDim dtSubFolderDates(objResultsFolders.Length - 1)

                    For Each objSubFolder In objResultsFolders
                        strSubFolderNames(intSubfolderCount) = objSubFolder.Name
                        dtSubFolderDates(intSubfolderCount) = objSubFolder.LastWriteTime
                        intSubfolderCount += 1
                    Next

                    If intSubfolderCount > 1 Then
                        Array.Sort(dtSubFolderDates, strSubFolderNames)
                    End If

                    blnResultsFolderExists = True
                    ResultsFolderName = strSubFolderNames(intSubfolderCount - 1)
                    ResultsFolderTimestamp = dtSubFolderDates(intSubfolderCount - 1)

                    strResultsFolderPath = System.IO.Path.Combine(objTransferFolderInfo.FullName, CStr(ResultsFolderName))
                    ResultsFolderPath = String.Copy(strResultsFolderPath)

                    Message = "Results folder path: " & strResultsFolderPath
                Else
                    Message = "Results folder for Job " & Job.ToString & " not found in the transfer folder: " & strTransferFolderPath
                End If

                If InfoOnly <> 0 Then
                    SqlContext.Pipe.Send(CStr(Message))
                End If

            Catch ex As Exception
                Message = "Error: Exception finding result folder name for Job " & Job.ToString & " in " & strTransferFolderPath
                Exit Sub
            End Try

            If blnResultsFolderExists Then
                Try
                    ' Look for file AnalysisSummary.txt in folder ResultsFolderName
                    If blnJobBrokerInUse Then
                        ' Obtain a list of all files ending in ANALYSIS_SUMMARY_FILE at strResultsFolderPath
                        objResultsFolderInfo = New System.IO.DirectoryInfo(strResultsFolderPath)
                        objAnalysisSummaryFiles = objTransferFolderInfo.GetFiles("*" & ANALYSIS_SUMMARY_FILE)

                        If objAnalysisSummaryFiles.Length > 0 Then
                            strAnalysisSummaryPath = objAnalysisSummaryFiles(0).FullName
                        End If
                    Else
                        strAnalysisSummaryPath = System.IO.Path.Combine(strResultsFolderPath, ANALYSIS_SUMMARY_FILE)
                    End If

                    If Not System.IO.File.Exists(strAnalysisSummaryPath) Then
                        Message = "Results folder path: " & strResultsFolderPath & "; " & ANALYSIS_SUMMARY_FILE & " not found"
                    Else

                        ' Make sure that the AnalysisSummary.txt file was modified over JobCompleteHoldoffMinutes ago
                        objFileInfo = New System.IO.FileInfo(strAnalysisSummaryPath)

                        If objFileInfo.LastWriteTime.AddMinutes(CDbl(JobCompleteHoldoffMinutes)) > System.DateTime.Now Then
                            Message = "Results folder path: " & strResultsFolderPath & "; " & ANALYSIS_SUMMARY_FILE & " file was found, but it was modified less than " & JobCompleteHoldoffMinutes.ToString & " minutes ago"
                        Else
                            Message = "Results folder path: " & strResultsFolderPath & "; " & ANALYSIS_SUMMARY_FILE & " exists and was modified " & objFileInfo.LastWriteTime.ToString("yyyy-MM-dd hh:mm:ss tt")

                            AnalysisManagerIsDone = 1

                            ' File exists; Open it and look for the line starting with "Fasta File Name	"
                            tsInFile = New System.IO.StreamReader(strAnalysisSummaryPath)

                            Do While tsInFile.Peek() >= 0
                                strLineIn = tsInFile.ReadLine

                                If Not strLineIn Is Nothing AndAlso strLineIn.ToLower.StartsWith(ORGANISM_DB_NAME_LINE_HEADER.ToLower) Then
                                    strFastaFileName = strLineIn.Substring(ORGANISM_DB_NAME_LINE_HEADER.Length + 1)

                                    If Not strFastaFileName Is Nothing Then
                                        strFastaFileName = strFastaFileName.TrimStart(ControlChars.Tab)
                                        strFastaFileName = strFastaFileName.TrimStart(" "c)
                                    End If
                                    Exit Do
                                End If
                            Loop

                            tsInFile.Close()

                            If Not strFastaFileName Is Nothing AndAlso strFastaFileName.Length > 0 Then
                                OrganismDBName = String.Copy(strFastaFileName)
                            Else
                                OrganismDBName = String.Empty
                            End If
                        End If
                    End If

                    If InfoOnly <> 0 Then
                        SqlContext.Pipe.Send(CStr(Message))
                    End If

                Catch ex As Exception
                    If strResultsFolderPath Is Nothing Then
                        strResultsFolderPath = "??"
                    End If
                    Message = "Error: Exception examining the " & ANALYSIS_SUMMARY_FILE & " file for Job " & Job.ToString & " in " & CStr(strResultsFolderPath)
                End Try

                If AnalysisManagerIsDone <> 0 And Not blnJobBrokerInUse Then
                    Try
                        ' Look for file DataExtractionSummary.txt in folder ResultsFolderName

                        strDEXSummaryPath = System.IO.Path.Combine(strResultsFolderPath, DEX_SUMMARY_FILE)

                        If System.IO.File.Exists(strDEXSummaryPath) Then

                            ' Make sure that the DataExtractionSummary.txt file was modified over JobCompleteHoldoffMinutes ago
                            objFileInfo = New System.IO.FileInfo(strDEXSummaryPath)

                            If objFileInfo.LastWriteTime.AddMinutes(CDbl(JobCompleteHoldoffMinutes)) > System.DateTime.Now Then
                                Message = DEX_SUMMARY_FILE & " file was found, but it was modified less than " & JobCompleteHoldoffMinutes.ToString & " minutes ago"
                            Else
                                Message = "Results folder path: " & strResultsFolderPath & "; " & DEX_SUMMARY_FILE & " exists and was modified " & objFileInfo.LastWriteTime.ToString("yyyy-MM-dd hh:mm:ss tt")

                                Try
                                    objResultsFolderForJob = New System.IO.DirectoryInfo(strResultsFolderPath)
                                    objFiles = objResultsFolderForJob.GetFiles("*" & SYN_FILE_SUFFIX)

                                    If objFiles.Length = 0 Then
                                        Message = SYN_FILE_SUFFIX & " not found in " & strResultsFolderPath & "; data extraction was not successful"
                                    Else
                                        Message = CStr(Message) & "; " & SYN_FILE_SUFFIX & " file was found"
                                        DataExtractionIsDone = 1
                                    End If

                                Catch ex As Exception

                                End Try
                            End If

                            If InfoOnly <> 0 Then
                                SqlContext.Pipe.Send(CStr(Message))
                            End If

                        End If

                    Catch ex As Exception
                        If strResultsFolderPath Is Nothing Then
                            strResultsFolderPath = "??"
                        End If
                        Message = "Error: Exception examining the " & DEX_SUMMARY_FILE & " file for Job " & Job.ToString & " in " & CStr(strResultsFolderPath)

                    End Try

                End If
            End If
        End If

    End Sub
End Class
