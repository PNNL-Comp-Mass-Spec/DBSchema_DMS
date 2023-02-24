/****** Object:  StoredProcedure [dbo].[AddUpdateLCCartConfiguration] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddUpdateLCCartConfiguration]
/****************************************************
**
**  Desc: Adds new or edits existing T_LC_Cart_Configuration entry
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   mem
**  Date:   02/02/2017 mem - Initial release
**          02/22/2017 mem - Add several new parameters to match the updated columns in T_LC_Cart_Configuration
**          02/23/2017 mem - Validate the config name
**          02/24/2017 mem - Add parameters @primaryTrapTime and @primaryTrapMobilePhase
**                         - Allow changing state even if the Cart Config is associated with datasets
**          02/28/2017 mem - Remove parameter @cartName
**                         - Validate that @configName starts with a valid cart name
**          03/03/2017 mem - Add parameter @entryUser
**          09/17/2018 mem - Update cart config name error message
**          03/03/2021 mem - Update admin-required message
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
    @ID int,
    @configName varchar(128),
    @description varchar(512),
    @autosampler varchar(128),
    @customValveConfig varchar(256),
    @pumps varchar(256),
    @primaryInjectionVolume varchar(64),
    @primaryMobilePhases varchar(128),
    @primaryTrapColumn varchar(128),
    @primaryTrapFlowRate varchar(64),
    @primaryTrapTime varchar(32),
    @primaryTrapMobilePhase varchar(128),
    @primaryAnalyticalColumn varchar(128),
    @primaryColumnTemperature varchar(64),
    @primaryAnalyticalFlowRate varchar(64),
    @primaryGradient varchar(512),
    @massSpecStartDelay varchar(64),
    @upstreamInjectionVolume varchar(64),
    @upstreamMobilePhases varchar(128),
    @upstreamTrapColumn varchar(128),
    @upstreamTrapFlowRate varchar(64),
    @upstreamAnalyticalColumn varchar(128),
    @upstreamColumnTemperature varchar(64),
    @upstreamAnalyticalFlowRate varchar(64),
    @upstreamFractionationProfile varchar(128),
    @upstreamFractionationDetails varchar(512),
    @entryUser varchar(128) = '',                    -- User who entered the LC Cart Configuration entry; defaults to @callingUser if empty
    @state varchar(12) = 'Active',                    -- Active, Inactive, Invalid, or Override (see comments below)
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @ID = IsNull(@ID, 0)
    Set @configName = IsNull(@configName, '')
    Set @state = IsNull(@state, 'Active')
    Set @entryUser = IsNull(@entryUser, '')
    Set @callingUser = IsNull(@callingUser, '')
    Set @mode = IsNull(@mode, 'add')

    If @state = ''
        Set @state = 'Active'

    ---------------------------------------------------
    -- Validate @state
    -- Note that table T_LC_Cart_Configuration also has a check constraint on the Cart_Config_State field
    --
    -- Override can only be used when @callingUser is a user with DMS_Infrastructure_Administration privileges
    -- When @state is Override, the state will be left unchanged, but data can still be updated
    -- even if the cart config is already associated with datasets
    ---------------------------------------------------
    --
    If Not @state IN ('Active', 'Inactive', 'Invalid', 'Override')
    Begin
        Set @message = 'Cart config state must be Active, Inactive, or Invalid; ' + @state + ' is not allowed'
        RAISERROR (@message, 10, 1)
        Return 51005
    End

    If Not Exists (Select U_PRN From T_Users Where U_PRN = @callingUser)
        Set @callingUser = null
    Else
    Begin
        If @entryUser = ''
            Set @entryUser = @callingUser
    End

    If @state = 'Override' and @mode <> 'Update'
    Begin
        Set @message = 'Cart config state must be Active, Inactive, or Invalid when @mode is ' + @mode + '; ' + @state + ' is not allowed'
    End

    ---------------------------------------------------
    -- Validate the cart configuration name
    -- First assure that it does not have invalid characters and is long enough
    ---------------------------------------------------

    Declare @badCh varchar(128) = dbo.ValidateChars(@configName, '')
    if @badCh <> ''
    begin
        If @badCh = '[space]'
            Set @message  ='LC Cart Configuration name may not contain spaces'
        Else
            Set @message = 'LC Cart Configuration name may not contain the character(s) "' + @badCh + '"'
        RAISERROR (@message, 10, 1)
        Return 51005
    end

    If Len(@configName) < 6
    Begin
        Set @message = 'LC Cart Configuration name must be at least 6 characters in length; currently ' + Cast(Len(@configName) as varchar(9)) + ' characters'
        RAISERROR (@message, 10, 1)
        Return 51005
    End

    ---------------------------------------------------
    -- Next assure that it starts with a valid cart name followed by an underscore, or starts with "Unknown_"
    ---------------------------------------------------
    --
    Declare @underscoreLoc int
    Declare @cartName varchar(128)

    Set @underscoreLoc = CharIndex('_', @configName)

    If @underscoreLoc <=1
    Begin
    Set @message = 'Cart Config name must start with a valid LC cart name, followed by an underscore'
        RAISERROR (@message, 10, 1)
        Return 51006
    End

    Set @cartName = Substring(@configName, 1, @underscoreLoc-1)

    If @cartName = 'Unknown'
        Set @cartName= 'No_Cart'

    ---------------------------------------------------
    -- Resolve cart name to ID
    ---------------------------------------------------
    --
    Declare @cartID int = 0
    --
    SELECT @cartID = ID
    FROM  T_LC_Cart
    WHERE Cart_Name = @cartName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error trying to resolve cart ID'
        RAISERROR (@message, 10, 1)
        Return 51006
    End

    If @cartID = 0
    Begin
        Set @message = 'Cart Config name must start with a valid LC cart name, followed by an underscore; unknown cart: ' + @cartName
        RAISERROR (@message, 10, 1)
        Return 51007
    End

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------
    --
    If @mode = 'update'
    Begin
        -- Lookup the current name and state
        Declare @existingName varchar(128) = ''
        Declare @oldState varchar(24) = ''
        Declare @ignoreDatasetChecks tinyint = 0
        Declare @existingEntryUser varchar(128) = ''

        SELECT @existingName = Cart_Config_Name,
               @oldState = Cart_Config_State,
               @existingEntryUser = Entered_By
        FROM T_LC_Cart_Configuration
        WHERE Cart_Config_ID = @ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin
            Set @message = 'No entry could be found in database for update'
            RAISERROR (@message, 10, 1)
            Return 51008
        End

        If @state = 'Override'
        Begin
            If Exists (
                SELECT *
                FROM T_Users U
                    INNER JOIN T_User_Operations_Permissions OpsPerms
                    ON U.ID = OpsPerms.U_ID
                    INNER JOIN T_User_Operations UserOps
                    ON OpsPerms.Op_ID = UserOps.ID
                WHERE U.U_PRN = @callingUser AND
                    UserOps.Operation = 'DMS_Infrastructure_Administration')
            Begin
                -- Admin user is updating details for an LC Cart Config that is already associated with datasets
                -- Use the existing state
                Set @state = @oldState
                Set @ignoreDatasetChecks = 1
            End
            Else
            Begin
                Set @message = 'Cart config state must be Active, Inactive, or Invalid; ' + @state + ' is not allowed'
                RAISERROR (@message, 10, 1)
                Return 51005
            End
        End

        If @configName <> @existingName
        Begin
            Declare @conflictID int = 0

            SELECT @conflictID = Cart_Config_ID
            FROM T_LC_Cart_Configuration
            WHERE Cart_Config_Name = @configName
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @conflictID > 0
            Begin
                Set @message = 'Cannot rename config from ' + @existingName + ' to ' + @configName + ' because the new name is already in use by ID ' + Cast(@conflictID as varchar(9))
                RAISERROR (@message, 10, 1)
                Return 51009
            End
        End

        If @entryUser = ''
        Begin
            Set @entryUser = @existingEntryUser
        End

        ---------------------------------------------------
        -- Only allow updating the state of Cart Config items that are associated with a dataset
        ---------------------------------------------------
        --
        If @ignoreDatasetChecks = 0 And Exists (Select * FROM T_Dataset Where Cart_Config_ID = @ID)
        Begin
            Declare @datasetCount int = 0
            Declare @maxDatasetID int = 0

            SELECT @datasetCount = Count(*),
                   @maxDatasetID = Max(Dataset_ID)
            FROM T_Dataset
            WHERE Cart_Config_ID = @ID

            Declare @datasetDescription varchar(196)
            Declare @datasetName varchar(128)

            SELECT @datasetName = Dataset_Num
            FROM T_Dataset
            WHERE Dataset_ID = @maxDatasetID

            If @datasetCount = 1
                Set @datasetDescription = 'dataset ' + @datasetName
            Else
                Set @datasetDescription = Cast(@datasetCount as varchar(9)) + ' datasets'

            If @state <> @oldState
            Begin
                UPDATE T_LC_Cart_Configuration
                SET Cart_Config_State = @state
                WHERE Cart_Config_ID = @ID
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                Set @message = 'Updated state to ' + @state + '; any other changes were ignored because this cart config is associated with ' + @datasetDescription
                Return 0
            End

            Set @message = 'LC cart config ID ' + Cast(@ID as varchar(9)) + ' is associated with ' + @datasetDescription +
                           ', most recently ' + @datasetName + '; contact a DMS admin to update the configuration (using special state Override)'

            RAISERROR (@message, 10, 1)
            Return 51010
        End

    End

    ---------------------------------------------------
    -- Validate that the LC Cart Config name is unique when creating a new entry
    ---------------------------------------------------
    --
    If @mode = 'add'
    Begin
        If Exists (Select * FROM T_LC_Cart_Configuration Where Cart_Config_Name = @configName)
        Begin
            Set @message = 'LC Cart Config already exists; cannot add a new config named ' + @configName
            RAISERROR (@message, 10, 1)
            Return 51011
        End
    End

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------
    --
    If @mode = 'add'
    Begin

        INSERT INTO T_LC_Cart_Configuration( Cart_Config_Name,
                                             Cart_ID,
                                             Description,
                                             Autosampler,
                                             Custom_Valve_Config,
                                             Pumps,
                                             Primary_Injection_Volume,
                                             Primary_Mobile_Phases,
                                             Primary_Trap_Column,
                                             Primary_Trap_Flow_Rate,
                                             Primary_Trap_Time,
                                             Primary_Trap_Mobile_Phase,
                                             Primary_Analytical_Column,
                                             Primary_Column_Temperature,
                                             Primary_Analytical_Flow_Rate,
                                             Primary_Gradient,
                                             Mass_Spec_Start_Delay,
                                             Upstream_Injection_Volume,
                                             Upstream_Mobile_Phases,
                                             Upstream_Trap_Column,
                                             Upstream_Trap_Flow_Rate,
                                             Upstream_Analytical_Column,
                                             Upstream_Column_Temperature,
                                             Upstream_Analytical_Flow_Rate,
                                             Upstream_Fractionation_Profile,
                                             Upstream_Fractionation_Details,
                                             Cart_Config_State,
                                             Entered,
                                             Entered_By,
                                             Updated,
                                             Updated_By )
        VALUES (
            @configName,
            @cartID,
            @description,
            @autosampler,
            @customValveConfig,
            @pumps,
            @primaryInjectionVolume,
            @primaryMobilePhases,
            @primaryTrapColumn,
            @primaryTrapFlowRate,
            @primaryTrapTime,
            @primaryTrapMobilePhase,
            @primaryAnalyticalColumn,
            @primaryColumnTemperature,
            @primaryAnalyticalFlowRate,
            @primaryGradient,
            @massSpecStartDelay,
            @upstreamInjectionVolume,
            @upstreamMobilePhases,
            @upstreamTrapColumn,
            @upstreamTrapFlowRate,
            @upstreamAnalyticalColumn,
            @upstreamColumnTemperature,
            @upstreamAnalyticalFlowRate,
            @upstreamFractionationProfile,
            @upstreamFractionationDetails,
            @state,
            GetDate(),
            @entryUser,
            GetDate(),
            @callingUser
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Insert operation failed'
            RAISERROR (@message, 10, 1)
            Return 51012
        End

        -- Return ID of newly created entry
        --
        Set @ID = SCOPE_IDENTITY()

    End -- add mode

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------
    --
    If @mode = 'update'
    Begin
        Set @myError = 0
        --
        UPDATE T_LC_Cart_Configuration
        SET Cart_Config_Name = @configName,
            Cart_ID = @cartID,
            Description = @description,
            Autosampler = @autosampler,
            Custom_Valve_Config = @customValveConfig,
            Pumps = @pumps,
            Primary_Injection_Volume = @primaryInjectionVolume,
            Primary_Mobile_Phases = @primaryMobilePhases,
            Primary_Trap_Column = @primaryTrapColumn,
            Primary_Trap_Flow_Rate = @primaryTrapFlowRate,
            Primary_Trap_Time = @primaryTrapTime,
            Primary_Trap_Mobile_Phase = @primaryTrapMobilePhase,
            Primary_Analytical_Column = @primaryAnalyticalColumn,
            Primary_Column_Temperature = @primaryColumnTemperature,
            Primary_Analytical_Flow_Rate = @primaryAnalyticalFlowRate,
            Primary_Gradient = @primaryGradient,
            Mass_Spec_Start_Delay = @massSpecStartDelay,
            Upstream_Injection_Volume = @upstreamInjectionVolume,
            Upstream_Mobile_Phases = @upstreamMobilePhases,
            Upstream_Trap_Column = @upstreamTrapColumn,
            Upstream_Trap_Flow_Rate = @upstreamTrapFlowRate,
            Upstream_Analytical_Column = @upstreamAnalyticalColumn,
            Upstream_Column_Temperature = @upstreamColumnTemperature,
            Upstream_Analytical_Flow_Rate = @upstreamAnalyticalFlowRate,
            Upstream_Fractionation_Profile = @upstreamFractionationProfile,
            Upstream_Fractionation_Details = @upstreamFractionationDetails,
            Cart_Config_State = @state,
            Entered_By = @entryUser,
            Updated = GetDate(),
            Updated_By = @callingUser
        WHERE Cart_Config_ID = @ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Update operation failed: "' + Cast(@ID as varchar(12)) + '"'
            RAISERROR (@message, 10, 1)
            Return 51013
        End

    End -- update mode

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateLCCartConfiguration] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateLCCartConfiguration] TO [DMS_Analysis] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateLCCartConfiguration] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateLCCartConfiguration] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateLCCartConfiguration] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateLCCartConfiguration] TO [Limited_Table_Write] AS [dbo]
GO
