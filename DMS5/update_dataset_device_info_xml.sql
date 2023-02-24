/****** Object:  StoredProcedure [dbo].[UpdateDatasetDeviceInfoXML] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateDatasetDeviceInfoXML]
/****************************************************
**
**  Desc:   Adds (or updates) information about the device (or devices) for a dataset
**          Adds new devices to T_Dataset_Device as necessary
**
**          Device information is provided via XML, using the same format as recognized by UpdateDatasetFileInfoXML, for example:
**
**      Typical XML file contents:
**
**      <DatasetInfo>
**        <Dataset>Sample_Name_W_F20</Dataset>
**        <ScanTypes>
**          <ScanType ScanCount="17060" ScanFilterText="FTMS + p NSI Full ms">HMS</ScanType>
**          <ScanType ScanCount="61336" ScanFilterText="FTMS + p NSI d Full ms2 0@hcd32.00">HCD-HMSn</ScanType>
**        </ScanTypes>
**        <AcquisitionInfo>
**          <ScanCount>78396</ScanCount>
**          <ScanCountMS>17060</ScanCountMS>
**          <ScanCountMSn>61336</ScanCountMSn>
**          <Elution_Time_Max>210.00</Elution_Time_Max>
**          <AcqTimeMinutes>210.00</AcqTimeMinutes>
**          <StartTime>2019-12-29 08:28:22 PM</StartTime>
**          <EndTime>2019-12-29 11:58:22 PM</EndTime>
**          <FileSizeBytes>3555625312</FileSizeBytes>
**          <InstrumentFiles>
**            <InstrumentFile Hash="4677d34d0f02999f5bddd01fc30b6941f64841da" HashType="SHA1" Size="3555625312">Sample_Name_W_F20.raw</InstrumentFile>
**          </InstrumentFiles>
**          <DeviceList>
**            <Device Type="MS" Number="1" Name="Q Exactive HF-X Orbitrap" Model="Q Exactive HF-X Orbitrap"
**                    SerialNumber="Exactive Series slot #6000" SoftwareVersion="2.9-290033/2.9.0.2926">
**              Mass Spectrometer
**            </Device>
**            <Device Type="Analog" Number="1" Name="Dionex.PumpNCS3500RS" Model="NCS-3500RS"
**                    SerialNumber="8140000" SoftwareVersion="">
**              Analog device #1
**            </Device>
**          </DeviceList>
**        </AcquisitionInfo>
**        ...
**      </DatasetInfo>
**
**  Auth:   mem
**  Date:   03/01/2020 mem - Initial version
**
*****************************************************/
(
    @datasetID int = 0,                 -- If this value is 0, will determine the dataset ID using the contents of @deviceInfoXML by looking for <Dataset>DatasetName</Dataset>
    @datasetInfoXML xml,                -- Dataset info, in XML format
    @message varchar(512) = '' Output,
    @infoOnly tinyint = 0,
    @skipValidation tinyint = 0         -- When 1, if @datasetID is non-zero, skip calling GetDatasetDetailsFromDatasetInfoXML
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @datasetName varchar(128)
    Declare @datasetIDCheck int

    Declare @msg Varchar(1024)
    Declare @datasetIdText varchar(12) = Cast(@datasetID as varchar(12))

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'UpdateDatasetDeviceInfoXML', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    -----------------------------------------------------------
    -- Create a temp table to hold the data
    -----------------------------------------------------------

    Declare @DatasetDevicesTable table (
        Device_Type varchar(64),
        Device_Number_Text varchar(64),
        Device_Number int Null,
        Device_Name varchar(128),
        Device_Model varchar(128),
        Device_Serial_Number varchar(128),
        Device_Software_Version varchar(128),
        Device_Description varchar(128),
        Device_ID Int null
    )

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @datasetID = Coalesce(@datasetID, 0);
    Set @message = '';
    Set @infoOnly = Coalesce(@infoOnly, 0);
    Set @skipValidation = Coalesce(@skipValidation, 0);

    If @datasetID > 0 And @skipValidation = 0
    Begin
        ---------------------------------------------------
        -- Examine the XML to determine the dataset name and update or validate @datasetID
        ---------------------------------------------------
        --
        Exec GetDatasetDetailsFromDatasetInfoXML
            @datasetInfoXML,
            @datasetID = @datasetID Output,
            @datasetName = @datasetName Output,
            @message = @message Output,
            @returnCode = @myError Output

        If @myError <> 0
        Begin
            Goto Done
        End

        If @datasetID = 0
        Begin
            Set @message = 'Procedure GetDatasetDetailsFromDatasetInfoXML was unable to determine the dataset ID value'
            Goto Done
        End
    End

    ---------------------------------------------------
    -- Parse the contents of @datasetInfoXML to populate @@DatasetDevicesTable
    -- Skip the StartTime and EndTime values for now since they might have invalid dates
    ---------------------------------------------------
    --
    INSERT INTO @DatasetDevicesTable (
        Device_Type,
        Device_Number_Text,
        Device_Name,
        Device_Model,
        Device_Serial_Number,
        Device_Software_Version,
        Device_Description
    )
    SELECT Device_Type, Device_Number_Text,
           Device_Name, Device_Model, Device_Serial_Number,
           Device_Software_Version, Device_Description
    FROM ( SELECT xmlNode.value('@Type', 'varchar(64)') AS Device_Type,
                  xmlNode.value('@Number', 'varchar(128)') AS Device_Number_Text,
                  xmlNode.value('@Name', 'varchar(128)') AS Device_Name,
                  xmlNode.value('@Model', 'varchar(128)') AS Device_Model,
                  xmlNode.value('@SerialNumber', 'varchar(128)') AS Device_Serial_Number,
                  xmlNode.value('@SoftwareVersion', 'varchar(128)') AS Device_Software_Version,
                  xmlNode.value('.', 'varchar(128)') AS Device_Description
           FROM @datasetInfoXML.nodes('/DatasetInfo/AcquisitionInfo/DeviceList/Device') AS R(xmlNode)
    ) LookupQ
    WHERE Not Device_Type IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error parsing Device nodes in @datasetInfoXML for DatasetID ' + @datasetIdText + ' in SP UpdateDatasetDeviceInfoXML'
        Goto Done
    End
    --

    -- Populate the Device_Number column
    Update @DatasetDevicesTable
    Set Device_Number = Try_Cast(Device_Number_Text As Int)

    ---------------------------------------------------
    -- Look for matching devices in T_Dataset_Device
    ---------------------------------------------------

    UPDATE @DatasetDevicesTable
    SET Device_ID = DD.Device_ID
    FROM @DatasetDevicesTable Src
         INNER JOIN T_Dataset_Device DD
           ON DD.Device_Type = Src.Device_Type AND
              DD.Device_Name = Src.Device_Name AND
              DD.Device_Model = Src.Device_Model AND
              DD.Serial_Number = Src.Device_Serial_Number AND
              DD.Software_Version = Src.Device_Software_Version
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @infoOnly = 0
    Begin
        ---------------------------------------------------
        -- Add new devices
        ---------------------------------------------------
        --
        INSERT INTO T_Dataset_Device(
            Device_Type, Device_Number,
            Device_Name, Device_Model,
            Serial_Number, Software_Version,
            Device_Description )
        SELECT Src.Device_Type,
               Src.Device_Number,
               Src.Device_Name,
               Src.Device_Model,
               Src.Device_Serial_Number,
               Src.Device_Software_Version,
               Src.Device_Description
        FROM @DatasetDevicesTable Src
        WHERE Src.Device_ID IS NULL
        ORDER BY Src.Device_Type DESC, Src.Device_Number
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        ---------------------------------------------------
        -- Look, again for matching devices in T_Dataset_Device
        ---------------------------------------------------

        UPDATE @DatasetDevicesTable
        SET Device_ID = DD.Device_ID
        FROM @DatasetDevicesTable Src
             INNER JOIN T_Dataset_Device DD
               ON DD.Device_Type = Src.Device_Type AND
                  DD.Device_Name = Src.Device_Name AND
                  DD.Device_Model = Src.Device_Model AND
                  DD.Serial_Number = Src.Device_Serial_Number AND
                  DD.Software_Version = Src.Device_Software_Version
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        ---------------------------------------------------
        -- Add/update T_Dataset_Device_Map
        ---------------------------------------------------

        -- Remove any existing froms from T_Dataset_Device_Map
        DELETE T_Dataset_Device_Map
        WHERE Dataset_ID = @datasetID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        INSERT INTO T_Dataset_Device_Map( Dataset_ID, Device_ID )
        SELECT DISTINCT @datasetID,
                        Src.Device_ID
        FROM @DatasetDevicesTable Src
        WHERE NOT Src.Device_ID IS NULL
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

    End
    Else
    Begin
        -- Preview new devices
        SELECT 'New device' As Info_Message,
               Src.Device_Type,
               Src.Device_Number,
               Src.Device_Name,
               Src.Device_Model,
               Src.Device_Serial_Number,
               Src.Device_Software_Version,
               Src.Device_Description
        FROM @DatasetDevicesTable Src
        WHERE Src.Device_ID IS NULL
        Union
        SELECT 'Existing device, ID ' + Cast(DD.Device_ID AS varchar(12)) AS Info_Message,
               DD.Device_Type,
               DD.Device_Number,
               DD.Device_Name,
               DD.Device_Model,
               DD.Serial_Number,
               DD.Software_Version,
               DD.Device_Description
        FROM @DatasetDevicesTable Src
             INNER JOIN T_Dataset_Device DD
               ON Src.Device_ID = DD.Device_ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End

Done:

    If @myError <> 0
    Begin
        If @message = ''
            Set @message = 'Error in UpdateDatasetDeviceInfoXML'

        Set @message = @message + '; error code = ' + Convert(varchar(12), @myError)

        If @InfoOnly = 0
            Exec PostLogEntry 'Error', @message, 'UpdateDatasetDeviceInfoXML'
    End

    If Len(@message) > 0 AND @InfoOnly <> 0
        Print @message

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDatasetDeviceInfoXML] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateDatasetDeviceInfoXML] TO [DMS_DS_Entry] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateDatasetDeviceInfoXML] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateDatasetDeviceInfoXML] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDatasetDeviceInfoXML] TO [Limited_Table_Write] AS [dbo]
GO
