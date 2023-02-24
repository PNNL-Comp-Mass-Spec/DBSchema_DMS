/****** Object:  StoredProcedure [dbo].[StoreBionetHosts] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[StoreBionetHosts]
/****************************************************
**
**  Updates the entries in T_Bionet_Hosts
**
**  Export the list of computers from DNS on Gigasax
**  by right clicking Bionet under "Forward Lookup Zones"
**  and choosing "Export list ..."
**        
**  File format (tab-separated)
**
**     Name    Type    Data
**     (same as parent folder)    Host (A)    192.168.30.0
**     (same as parent folder)    Start of Authority (SOA)    [1102], gigasax.bionet., 
**     (same as parent folder)    Name Server (NS)    gigasax.bionet.
**     12t_agilent    Host (A)    192.168.30.61
**     12tfticr64     Host (A)    192.168.30.54
**     15t_fticr_2    Host (A)    192.168.30.80
**     15tfticr64     Host (A)    192.168.30.62
**     21tfticr       Host (A)    192.168.30.60
**     21tvpro        Host (A)    192.168.30.60
**
**  Auth:   mem
**  Date:   12/02/2015 mem - Initial version
**          11/19/2018 mem - Pass 0 to the @maxRows parameter to udfParseDelimitedListOrdered
**    
*****************************************************/
(
    @hostList varchar(max),
    @infoOnly tinyint = 0,
    @message varchar(512)='' output
)
AS
    Set NoCount On

    Declare @myRowCount int = 0
    Declare @myError int = 0
    
    -----------------------------------------
    -- Validate the input parameters
    -----------------------------------------
    
    Set @hostList = IsNull(@hostList, '')
    Set @infoOnly = IsNull(@infoOnly, 0)
    
    Set @message = ''
    
    If @hostList = ''
    Begin
        Set @message = '@hostList cannot be empty; unable to continue'
        Set @myError = 53000
        Goto Done
    End

    -----------------------------------------
    -- Create some temporary tables
    -----------------------------------------
    
    CREATE TABLE #Tmp_HostData (
        EntryID int not null identity(1,1),
        Value varchar(2048) null
    )
    
    CREATE UNIQUE INDEX #IX_Tmp_Hosts_EntryID ON #Tmp_HostData (EntryID)

    CREATE TABLE #Tmp_Hosts (
        Host varchar(64) not null,
        NameOrIP varchar(64) not null,
        IsAlias tinyint not null,
        Instruments varchar(1024) null
    )
    
    CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_Hosts ON #Tmp_Hosts (Host)

    CREATE TABLE #Tmp_DataColumns (
        EntryID int not null,
        Value varchar(2048) null
    )
    
    CREATE UNIQUE INDEX #IX_Tmp_DataColumns_EntryID ON #Tmp_DataColumns (EntryID)
    
    -----------------------------------------
    -- Split @hostList on carriage returns
    -- Store the data in #Tmp_Hosts
    -----------------------------------------

    Declare @Delimiter varchar(1) = ''

    If CHARINDEX(CHAR(10), @hostList) > 0
        Set @Delimiter = CHAR(10)
    Else
        Set @Delimiter = CHAR(13)
    
    INSERT INTO #Tmp_HostData (Value)
    SELECT Item
    FROM dbo.MakeTableFromListDelim ( @hostList, @Delimiter )
    --
    SELECT @myRowCount = @@rowcount, @myError = @@error
    
    If Not Exists (SELECT * FROM #Tmp_HostData)
    Begin
        Set @message = 'Nothing returned when splitting the Host List on CR or LF'
        Set @myError = 53004
        Goto Done
    End
    
    Declare @Continue tinyint = 1
    Declare @EntryID int = 0
    Declare @EntryIDEnd int = 0
    
    Declare @CharIndex int
    Declare @ColCount int

    Declare @Row varchar(2048)
    
    Declare @HostName varchar(64)
    Declare @HostType varchar(64)
    Declare @HostData varchar(64)
    Declare @Instruments varchar(1024)
    Declare @IsAlias tinyint
    
    SELECT @EntryIDEnd = MAX(EntryID)
    FROM #Tmp_HostData
    
    -----------------------------------------
    -- Parse the host list
    -----------------------------------------
    --
    While @EntryID < @EntryIDEnd
    Begin
        SELECT TOP 1 @EntryID = EntryID, @Row = Value
        FROM #Tmp_HostData
        WHERE EntryID > @EntryID
        ORDER BY EntryID
        --
        SELECT @myRowCount = @@rowcount, @myError = @@error
        
        -- @Row should now be empty, or contain something like the following:
        -- 12tfticr64    Host (A)    192.168.30.54
        --   or
        -- agilent_qtof_02    Alias (CNAME)    agqtof02.
        
        Set @Row = Replace (@Row, CHAR(10), '')
        Set @Row = Replace (@Row, CHAR(13), '')
        Set @Row = LTrim(RTrim(IsNull(@Row, '')))
        
        If @Row <> ''
        Begin

            -- Split the row on tabs to find HostName, HostType, and HostData
            TRUNCATE TABLE #Tmp_DataColumns
            Set @Delimiter = CHAR(9)
            
            INSERT INTO #Tmp_DataColumns (EntryID, Value)
            SELECT EntryID, Value
            FROM dbo.udfParseDelimitedListOrdered(@Row, @Delimiter, 0)
            --
            SELECT @myRowCount = @@rowcount, @myError = @@error

            If @myRowCount < 3
            Begin
                Print 'Skipping row since less than 3 columns: ' + @Row
            End
            Else
            Begin
                Set @HostName = ''
                Set @HostType = ''
                Set @HostData = ''
                Set @Instruments = ''
                Set @IsAlias = 0
                
                SELECT @HostName = Value FROM #Tmp_DataColumns WHERE EntryID = 1
                SELECT @HostType = Value FROM #Tmp_DataColumns WHERE EntryID = 2
                SELECT @HostData = Value FROM #Tmp_DataColumns WHERE EntryID = 3
                
                If @HostName = '' or @HostType = '' Or @HostData = ''
                Begin
                    Print 'Skipping row since 1 or more columns are blank: ' + @Row
                End
                Else
                Begin
                    If @HostName <> '(same as parent folder)' And Not (@HostName = 'Name' And @HostType = 'Type')
                    Begin
                        If @HostType Like 'Alias%'
                        Begin
                            Set @IsAlias = 1
                            
                            If @HostData Like '%.'
                                Set @HostData = SubString(@HostData, 1, Len(@HostData)-1)
                        End
                        
                        -- Look for instruments that have an inbox on this host
                        --
                        SELECT @Instruments = @Instruments + ', ' + Inst.IN_name
                        FROM T_Storage_Path SPath
                             INNER JOIN T_Instrument_Name Inst
                               ON SPath.SP_path_ID = Inst.IN_source_path_ID
                        WHERE (SPath.SP_machine_name = @HostName OR
                               SPath.SP_machine_name = @HostName + '.bionet') AND
                              (SPath.SP_function LIKE '%inbox%')
                        ORDER BY Inst.IN_Name

                        If Len(@Instruments) > 0
                            Set @Instruments = Substring(@Instruments, 3, Len(@Instruments))
                            
                        INSERT INTO #Tmp_Hosts (Host, NameOrIP, IsAlias, Instruments)
                        VALUES (@HostName, @HostData, @IsAlias, @Instruments)
    
                    End
                End
            End
            
        End
    End
    
    
    If @infoOnly <> 0
    Begin
        -- Preview the new info
        SELECT *
        FROM #Tmp_Hosts
    End
    Else
    Begin
        -- Store the host information

        -- Add/update hosts
        MERGE T_Bionet_Hosts AS t
        USING (SELECT Host, NameOrIP AS IP, Instruments
                FROM #Tmp_Hosts
                WHERE IsAlias = 0) as s
        ON ( t.[Host] = s.[Host])
        WHEN MATCHED AND (
            ISNULL( NULLIF(t.[IP], s.[IP]),
                    NULLIF(s.[IP], t.[IP])) IS NOT NULL OR
            ISNULL( NULLIF(t.[Instruments], s.[Instruments]),
                    NULLIF(s.[Instruments], t.[Instruments])) IS NOT NULL    
            )
        THEN UPDATE SET 
            [IP] = s.[IP],
            [Instruments] = s.[Instruments]
        WHEN NOT MATCHED BY TARGET THEN
            INSERT([Host], [IP], [Instruments])
            VALUES(s.[Host], s.[IP], s.[Instruments])
        ;

        -- Remove out-of-date aliases
        --
        UPDATE T_Bionet_Hosts
        SET Alias = Null
        FROM T_Bionet_Hosts Target             
             LEFT OUTER JOIN ( SELECT Host AS Alias,
                                      NameOrIP AS TargetHost
                               FROM #Tmp_Hosts
                               WHERE IsAlias = 1 ) Src
               ON Target.Host = Src.TargetHost AND
                  Target.Alias = Src.Alias
        WHERE IsNull(Target.Alias, '') <> '' AND Src.Alias IS NULL
        --
        SELECT @myRowCount = @@rowcount, @myError = @@error
                      
        -- Add/update aliases
        --        
        UPDATE T_Bionet_Hosts
        SET Alias = Src.Alias
        FROM T_Bionet_Hosts Target
             INNER JOIN ( SELECT Host AS Alias,
                                 NameOrIP AS TargetHost
                          FROM #Tmp_Hosts
                          WHERE IsAlias = 1 ) Src
               ON Target.Host = Src.TargetHost
        --
        SELECT @myRowCount = @@rowcount, @myError = @@error

        
    End

    
Done:
    If Len(@message) > 0
        SELECT @message As Message
    
    --
    Return @myError



GO
GRANT VIEW DEFINITION ON [dbo].[StoreBionetHosts] TO [DDL_Viewer] AS [dbo]
GO
