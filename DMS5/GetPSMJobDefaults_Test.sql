Use DMS5_T3

declare 
    @datasets varchar(max), 
    @Metadata varchar(2048),  
    @toolName varchar(64) ,
    @jobTypeName varchar(64) ,
    @jobTypeDesc varchar(255) ,
    @DynMetOxEnabled tinyint ,    
    @StatCysAlkEnabled tinyint ,
    @DynSTYPhosEnabled tinyint ,
    @organismName varchar(128) ,
    @protCollNameList varchar(1024) ,
    @protCollOptionsList varchar(256),
    @message varchar(512) 
    
    -- DMS5 datasets
    -- set @datasets = 'NS_7002_C_Globe_12m_A_13Mar12_Doc_12-02-12, NS_7002_C_Globe_12m_B_13Mar12_Doc_12-02-15, NS_7002_C_Globe_15m_A_13Mar12_Doc_12-02-12'

    -- DMS5_T3 datasets    
    set @datasets = 'EIF_TIF_07-0146C_01_28Feb08_Andromeda_07-08-08, EIF_TIF_07-0146C_02_28Feb08_Andromeda_07-11-17, EIF_TIF_07-0146C_03_28Feb08_Andromeda_07-10-08'
    
exec GetPSMJobDefaults 
    @datasets output, 
    @Metadata output,  
    @toolName  output,
    @jobTypeName  output,
    @jobTypeDesc  output,
    @DynMetOxEnabled output,    
    @StatCysAlkEnabled output,
    @DynSTYPhosEnabled output,
    @organismName  output,
    @protCollNameList  output,
    @protCollOptionsList output,
    @message output
    
select 
    @Metadata  as Metadata,  
    @toolName  as Tool,
    @jobTypeName  as JobTypeName,
    @jobTypeDesc  as JobTypeDesc,
    @DynMetOxEnabled AS DynMetOxEnabled,    
    @StatCysAlkEnabled AS StatCysAlkEnabled,
    @DynSTYPhosEnabled AS DynSTYPhosEnabled ,
    @organismName  as Organism,
    @protCollNameList  as ProteinCollectionList,
    @protCollOptionsList as CollectionOptions,
    @message  as Message
    
    print @Metadata
