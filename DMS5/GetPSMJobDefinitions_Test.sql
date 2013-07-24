Use DMS5_T3

 declare @datasets varchar(max),		-- Input/output parameter; comma-separated list of datasets; will be alphabetized after removing duplicates
	@metadata varchar(2048),		-- Output parameter; table of metadata with columns separated by colons and rows separated by vertical bars
    @defaults varchar(2048),		-- default values
    @mode varchar(12) = 'PSM',			-- someday, other types?
    @message varchar(512)
   

    -- DMS5 datasets
    -- set @datasets = 'NS_7002_C_Globe_12m_A_13Mar12_Doc_12-02-12, NS_7002_C_Globe_12m_B_13Mar12_Doc_12-02-15, NS_7002_C_Globe_15m_A_13Mar12_Doc_12-02-12'
    
    set @datasets = 'EIF_TIF_07-0146C_01_28Feb08_Andromeda_07-08-08, EIF_TIF_07-0146C_02_28Feb08_Andromeda_07-11-17, EIF_TIF_07-0146C_03_28Feb08_Andromeda_07-10-08'


exec GetPSMJobDefinitions   @datasets  OUTPUT,		-- Input/output parameter; comma-separated list of datasets; will be alphabetized after removing duplicates
	@metadata  OUTPUT,		-- Output parameter; table of metadata with columns separated by colons and rows separated by vertical bars
    @defaults  OUTPUT,		-- default values
    @mode,			-- someday, other types?
    @message output
    
    select @metadata, @defaults, @mode, @message