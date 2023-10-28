/****** Object:  Table [T_Instrument_Class] ******/
/****** RowCount: 33 ******/
/****** Columns: IN_class, is_purgable, raw_data_type, requires_preparation, x_Allowed_Dataset_Types, Params, Comment ******/
INSERT INTO [T_Instrument_Class] VALUES ('AB_Sequencer',1,'ab_sequencing_folder',0,null,null,'AB Next Gen Sequencer')
INSERT INTO [T_Instrument_Class] VALUES ('Agilent_Ion_Trap',1,'dot_d_folders',0,null,'<sections><section name="DatasetQC"><item key="SaveTICAndBPIPlots" value="True" /><item key="SaveLCMS2DPlots" value="True" /><item key="ComputeOverallQualityScores" value="True" /><item key="CreateDatasetInfoFile" value="True" /><item key="LCMS2DPlotMZResolution" value="0.4" /><item key="LCMS2DPlotMaxPointsToPlot" value="200000" /><item key="LCMS2DPlotMinPointsPerSpectrum" value="2" /><item key="LCMS2DPlotMinIntensity" value="0" /><item key="LCMS2DOverviewPlotDivisor" value="10" /></section></sections>','.D directory with a DATA.MS file. Used by both Agilent LC-MS ion traps and Agilent GCs.')
INSERT INTO [T_Instrument_Class] VALUES ('Agilent_TOF',0,'dot_wiff_files',0,null,'<sections><section name="DatasetQC"><item key="SaveTICAndBPIPlots" value="True" /><item key="SaveLCMS2DPlots" value="True" /><item key="ComputeOverallQualityScores" value="True" /><item key="CreateDatasetInfoFile" value="True" /><item key="LCMS2DPlotMZResolution" value="0.4" /><item key="LCMS2DPlotMaxPointsToPlot" value="200000" /><item key="LCMS2DPlotMinPointsPerSpectrum" value="2" /><item key="LCMS2DPlotMinIntensity" value="0" /><item key="LCMS2DOverviewPlotDivisor" value="10" /></section></sections>',null)
INSERT INTO [T_Instrument_Class] VALUES ('Agilent_TOF_V2',1,'dot_d_folders',0,null,'<sections><section name="DatasetQC"><item key="SaveTICAndBPIPlots" value="True" /><item key="SaveLCMS2DPlots" value="True" /><item key="ComputeOverallQualityScores" value="True" /><item key="CreateDatasetInfoFile" value="True" /><item key="LCMS2DPlotMZResolution" value="0.4" /><item key="LCMS2DPlotMaxPointsToPlot" value="200000" /><item key="LCMS2DPlotMinPointsPerSpectrum" value="2" /><item key="LCMS2DPlotMinIntensity" value="0" /><item key="LCMS2DOverviewPlotDivisor" value="10" /></section></sections>','.D directory with an AcqData subdirectory that has one or more .Bin files (for example MSScan.bin, MSPeak.bin, and MSProfile.bin) plus also a MSTS.xml file and a .m method directory')
INSERT INTO [T_Instrument_Class] VALUES ('Bruker_Amazon_Ion_Trap',1,'bruker_ft',0,null,'<sections><section name="DatasetQC"><item key="SaveTICAndBPIPlots" value="True" /><item key="SaveLCMS2DPlots" value="True" /><item key="ComputeOverallQualityScores" value="True" /><item key="CreateDatasetInfoFile" value="True" /><item key="LCMS2DPlotMZResolution" value="0.4" /><item key="LCMS2DPlotMaxPointsToPlot" value="200000" /><item key="LCMS2DPlotMinPointsPerSpectrum" value="2" /><item key="LCMS2DPlotMinIntensity" value="0" /><item key="LCMS2DOverviewPlotDivisor" value="10" /></section></sections>','.D directories that have analysis.yep and extension.baf files; .m directory has EsquireAcquisition.Method file')
INSERT INTO [T_Instrument_Class] VALUES ('BrukerFT_BAF',1,'bruker_ft',0,null,'<sections><section name="DatasetQC"><item key="SaveTICAndBPIPlots" value="True" /><item key="SaveLCMS2DPlots" value="True" /><item key="ComputeOverallQualityScores" value="True" /><item key="CreateDatasetInfoFile" value="True" /><item key="LCMS2DPlotMZResolution" value="0.4" /><item key="LCMS2DPlotMaxPointsToPlot" value="200000" /><item key="LCMS2DPlotMinPointsPerSpectrum" value="2" /><item key="LCMS2DPlotMinIntensity" value="0" /><item key="LCMS2DOverviewPlotDivisor" value="10" /></section></sections>','.D directories that have .BAF files and ser or fid files; .m directory has apexAcquisition.method file; used on Bruker 9T, 12T, and 15T')
INSERT INTO [T_Instrument_Class] VALUES ('BRUKERFTMS',1,'zipped_s_folders',1,'No longer used: HMS, HMS-HMSn','<sections><section name="DatasetQC"><item key="SaveTICAndBPIPlots" value="True" /><item key="SaveLCMS2DPlots" value="True" /><item key="ComputeOverallQualityScores" value="True" /><item key="CreateDatasetInfoFile" value="True" /><item key="LCMS2DPlotMZResolution" value="0.4" /><item key="LCMS2DPlotMaxPointsToPlot" value="200000" /><item key="LCMS2DPlotMinPointsPerSpectrum" value="2" /><item key="LCMS2DPlotMinIntensity" value="0" /><item key="LCMS2DOverviewPlotDivisor" value="10" /></section></sections>','Old 9T format')
INSERT INTO [T_Instrument_Class] VALUES ('BrukerMALDI_Imaging',1,'bruker_maldi_imaging',0,null,'<sections><section name="DatasetQC"><item key="SaveTICAndBPIPlots" value="True" /><item key="SaveLCMS2DPlots" value="True" /><item key="ComputeOverallQualityScores" value="True" /><item key="CreateDatasetInfoFile" value="True" /><item key="LCMS2DPlotMZResolution" value="0.4" /><item key="LCMS2DPlotMaxPointsToPlot" value="200000" /><item key="LCMS2DPlotMinPointsPerSpectrum" value="2" /><item key="LCMS2DPlotMinIntensity" value="0" /><item key="LCMS2DOverviewPlotDivisor" value="10" /></section></sections>','Series of zipped subdirectories, with names like 0_R00X329.zip; subdirectories inside the .Zip files have fid files')
INSERT INTO [T_Instrument_Class] VALUES ('BrukerMALDI_Imaging_V2',1,'bruker_ft',0,null,'<sections><section name="DatasetQC"><item key="SaveTICAndBPIPlots" value="True" /><item key="SaveLCMS2DPlots" value="True" /><item key="ComputeOverallQualityScores" value="True" /><item key="CreateDatasetInfoFile" value="True" /><item key="LCMS2DPlotMZResolution" value="0.4" /><item key="LCMS2DPlotMaxPointsToPlot" value="200000" /><item key="LCMS2DPlotMinPointsPerSpectrum" value="2" /><item key="LCMS2DPlotMinIntensity" value="0" /><item key="LCMS2DOverviewPlotDivisor" value="10" /></section></sections>','.D directories that have a large ser file and large .mcf file; .m directory has apexAcquisition.method file')
INSERT INTO [T_Instrument_Class] VALUES ('BrukerMALDI_Spot',1,'bruker_maldi_spot',0,null,'<sections><section name="DatasetQC"><item key="SaveTICAndBPIPlots" value="True" /><item key="SaveLCMS2DPlots" value="True" /><item key="ComputeOverallQualityScores" value="True" /><item key="CreateDatasetInfoFile" value="True" /><item key="LCMS2DPlotMZResolution" value="0.4" /><item key="LCMS2DPlotMaxPointsToPlot" value="200000" /><item key="LCMS2DPlotMinPointsPerSpectrum" value="2" /><item key="LCMS2DPlotMinIntensity" value="0" /><item key="LCMS2DOverviewPlotDivisor" value="10" /></section></sections>','Bruker TOF_TOF; directory has a .EMF file and a single subdirectory that has an acqu file and fid file')
INSERT INTO [T_Instrument_Class] VALUES ('BrukerTOF_BAF',1,'bruker_tof_baf',0,null,'<sections><section name="DatasetQC"><item key="SaveTICAndBPIPlots" value="True" /><item key="SaveLCMS2DPlots" value="True" /><item key="ComputeOverallQualityScores" value="True" /><item key="CreateDatasetInfoFile" value="True" /><item key="LCMS2DPlotMZResolution" value="0.4" /><item key="LCMS2DPlotMaxPointsToPlot" value="200000" /><item key="LCMS2DPlotMinPointsPerSpectrum" value="2" /><item key="LCMS2DPlotMinIntensity" value="0" /><item key="LCMS2DOverviewPlotDivisor" value="10" /></section></sections>','.D directories from Maxis instrument; have .BAF files but no ser or fid file; .m directory has microTOFQMaxAcquisition.method file')
INSERT INTO [T_Instrument_Class] VALUES ('BrukerTOF_TDF',1,'bruker_tof_tdf',0,null,'<sections><section name="DatasetQC"><item key="SaveTICAndBPIPlots" value="True" /><item key="SaveLCMS2DPlots" value="True" /><item key="ComputeOverallQualityScores" value="True" /><item key="CreateDatasetInfoFile" value="True" /><item key="LCMS2DPlotMZResolution" value="0.4" /><item key="LCMS2DPlotMaxPointsToPlot" value="200000" /><item key="LCMS2DPlotMinPointsPerSpectrum" value="2" /><item key="LCMS2DPlotMinIntensity" value="0" /><item key="LCMS2DOverviewPlotDivisor" value="10" /></section></sections>','.D directories from timsTOF instruments; have .tdf and .tdf_bin; .m directory has microTOFQImpacTemAcquisition.method')
INSERT INTO [T_Instrument_Class] VALUES ('Data_Folders',0,'data_folders',0,null,null,'Used for Broker DB analysis jobs')
INSERT INTO [T_Instrument_Class] VALUES ('Finnigan_FTICR',1,'zipped_s_folders',1,'No longer used: HMS, HMS-HMSn','<sections><section name="DatasetQC"><item key="SaveTICAndBPIPlots" value="True" /><item key="SaveLCMS2DPlots" value="True" /><item key="ComputeOverallQualityScores" value="True" /><item key="CreateDatasetInfoFile" value="True" /><item key="LCMS2DPlotMZResolution" value="0.4" /><item key="LCMS2DPlotMaxPointsToPlot" value="200000" /><item key="LCMS2DPlotMinPointsPerSpectrum" value="2" /><item key="LCMS2DPlotMinIntensity" value="0" /><item key="LCMS2DOverviewPlotDivisor" value="10" /></section></sections>',null)
INSERT INTO [T_Instrument_Class] VALUES ('Finnigan_Ion_Trap',1,'dot_raw_files',0,'No longer used: MS, MS-MSn, MS-ETD-MSn, MS-CID/ETD-MSn','<sections><section name="DatasetQC"><item key="SaveTICAndBPIPlots" value="True" /><item key="SaveLCMS2DPlots" value="True" /><item key="ComputeOverallQualityScores" value="True" /><item key="CreateDatasetInfoFile" value="True" /><item key="LCMS2DPlotMZResolution" value="0.4" /><item key="LCMS2DPlotMaxPointsToPlot" value="200000" /><item key="LCMS2DPlotMinPointsPerSpectrum" value="2" /><item key="LCMS2DPlotMinIntensity" value="0" /><item key="LCMS2DOverviewPlotDivisor" value="10" /></section></sections>',null)
INSERT INTO [T_Instrument_Class] VALUES ('FT_Booster_Data',1,'data_folders',0,null,null,'Data from a TI PXIe system, combining thermo .raw files with Agilent FT data')
INSERT INTO [T_Instrument_Class] VALUES ('GC_QExactive',1,'dot_raw_files',0,'n/a','<sections><section name="DatasetQC"><item key="SaveTICAndBPIPlots" value="True" /><item key="SaveLCMS2DPlots" value="True" /><item key="ComputeOverallQualityScores" value="True" /><item key="CreateDatasetInfoFile" value="True" /><item key="LCMS2DPlotMZResolution" value="0.4" /><item key="LCMS2DPlotMaxPointsToPlot" value="200000" /><item key="LCMS2DPlotMinPointsPerSpectrum" value="2" /><item key="LCMS2DPlotMinIntensity" value="0" /><item key="LCMS2DOverviewPlotDivisor" value="10" /></section></sections>',null)
INSERT INTO [T_Instrument_Class] VALUES ('Illumina_Sequencer',1,'illumina_folder',0,'','','.txt.gz fastq file')
INSERT INTO [T_Instrument_Class] VALUES ('IMS_Agilent_TOF_DotD',1,'dot_uimf_files',0,'','<sections><section name="DatasetQC"><item key="SaveTICAndBPIPlots" value="True" /><item key="SaveLCMS2DPlots" value="True" /><item key="ComputeOverallQualityScores" value="True" /><item key="CreateDatasetInfoFile" value="True" /><item key="LCMS2DPlotMZResolution" value="0.4" /><item key="LCMS2DPlotMaxPointsToPlot" value="200000" /><item key="LCMS2DPlotMinPointsPerSpectrum" value="2" /><item key="LCMS2DPlotMinIntensity" value="0" /><item key="LCMS2DOverviewPlotDivisor" value="10" /></section></sections>','Data is acquired natively as .D directories, which are then converted to .UIMF files')
INSERT INTO [T_Instrument_Class] VALUES ('IMS_Agilent_TOF_UIMF',1,'dot_uimf_files',0,'','<sections><section name="DatasetQC"><item key="SaveTICAndBPIPlots" value="True" /><item key="SaveLCMS2DPlots" value="True" /><item key="ComputeOverallQualityScores" value="True" /><item key="CreateDatasetInfoFile" value="True" /><item key="LCMS2DPlotMZResolution" value="0.4" /><item key="LCMS2DPlotMaxPointsToPlot" value="200000" /><item key="LCMS2DPlotMinPointsPerSpectrum" value="2" /><item key="LCMS2DPlotMinIntensity" value="0" /><item key="LCMS2DOverviewPlotDivisor" value="10" /></section></sections>','Data is acquired natively as .UIMF files')
INSERT INTO [T_Instrument_Class] VALUES ('IMS_Biospect_TOF',0,'biospec_folder',0,null,'<sections><section name="DatasetQC"><item key="SaveTICAndBPIPlots" value="True" /><item key="SaveLCMS2DPlots" value="True" /><item key="ComputeOverallQualityScores" value="True" /><item key="CreateDatasetInfoFile" value="True" /><item key="LCMS2DPlotMZResolution" value="0.4" /><item key="LCMS2DPlotMaxPointsToPlot" value="200000" /><item key="LCMS2DPlotMinPointsPerSpectrum" value="2" /><item key="LCMS2DPlotMinIntensity" value="0" /><item key="LCMS2DOverviewPlotDivisor" value="10" /></section></sections>','Unused')
INSERT INTO [T_Instrument_Class] VALUES ('IMS_Sciex_TOF',0,'dot_wiff_files',0,null,'<sections><section name="DatasetQC"><item key="SaveTICAndBPIPlots" value="True" /><item key="SaveLCMS2DPlots" value="True" /><item key="ComputeOverallQualityScores" value="True" /><item key="CreateDatasetInfoFile" value="True" /><item key="LCMS2DPlotMZResolution" value="0.4" /><item key="LCMS2DPlotMaxPointsToPlot" value="200000" /><item key="LCMS2DPlotMinPointsPerSpectrum" value="2" /><item key="LCMS2DPlotMinIntensity" value="0" /><item key="LCMS2DOverviewPlotDivisor" value="10" /></section></sections>','Unused')
INSERT INTO [T_Instrument_Class] VALUES ('LTQ_FT',1,'dot_raw_files',0,'No longer used: MS-MSn, HMS, HMS-MSn, HMS-HMSn, HMS-ETD-MSn, HMS-CID/ETD-MSn','<sections><section name="DatasetQC"><item key="SaveTICAndBPIPlots" value="True" /><item key="SaveLCMS2DPlots" value="True" /><item key="ComputeOverallQualityScores" value="True" /><item key="CreateDatasetInfoFile" value="True" /><item key="LCMS2DPlotMZResolution" value="0.4" /><item key="LCMS2DPlotMaxPointsToPlot" value="200000" /><item key="LCMS2DPlotMinPointsPerSpectrum" value="2" /><item key="LCMS2DPlotMinIntensity" value="0" /><item key="LCMS2DOverviewPlotDivisor" value="10" /></section></sections>','')
INSERT INTO [T_Instrument_Class] VALUES ('PrepHPLC',1,'dot_d_folders',0,null,null,'.D directories that have several .Reg files, a Run.Log file, and a SAMPLE.MAC file')
INSERT INTO [T_Instrument_Class] VALUES ('QStar_QTOF',0,'dot_wiff_files',0,null,'<sections><section name="DatasetQC"><item key="SaveTICAndBPIPlots" value="True" /><item key="SaveLCMS2DPlots" value="True" /><item key="ComputeOverallQualityScores" value="True" /><item key="CreateDatasetInfoFile" value="True" /><item key="LCMS2DPlotMZResolution" value="0.4" /><item key="LCMS2DPlotMaxPointsToPlot" value="200000" /><item key="LCMS2DPlotMinPointsPerSpectrum" value="2" /><item key="LCMS2DPlotMinIntensity" value="0" /><item key="LCMS2DOverviewPlotDivisor" value="10" /></section></sections>',null)
INSERT INTO [T_Instrument_Class] VALUES ('Sciex_QTrap',1,'sciex_wiff_files',0,null,'<sections><section name="DatasetQC"><item key="SaveTICAndBPIPlots" value="True" /><item key="SaveLCMS2DPlots" value="True" /><item key="ComputeOverallQualityScores" value="True" /><item key="CreateDatasetInfoFile" value="True" /><item key="LCMS2DPlotMZResolution" value="0.4" /><item key="LCMS2DPlotMaxPointsToPlot" value="200000" /><item key="LCMS2DPlotMinPointsPerSpectrum" value="2" /><item key="LCMS2DPlotMinIntensity" value="0" /><item key="LCMS2DOverviewPlotDivisor" value="10" /></section></sections>','AB Sciex QTrap.  Each dataset has a .wiff file and a .wiff.scan file.')
INSERT INTO [T_Instrument_Class] VALUES ('Sciex_TripleTOF',1,'dot_mzml_files',0,null,'<sections><section name="DatasetQC"><item key="SaveTICAndBPIPlots" value="True" /><item key="SaveLCMS2DPlots" value="True" /><item key="ComputeOverallQualityScores" value="True" /><item key="CreateDatasetInfoFile" value="True" /><item key="LCMS2DPlotMZResolution" value="0.4" /><item key="LCMS2DPlotMaxPointsToPlot" value="200000" /><item key="LCMS2DPlotMinPointsPerSpectrum" value="2" /><item key="LCMS2DPlotMinIntensity" value="0" /><item key="LCMS2DOverviewPlotDivisor" value="10" /></section></sections>','AB Sciex TripleTOF.  Original data converted to .mzML format')
INSERT INTO [T_Instrument_Class] VALUES ('Shimadzu_GC',1,'dot_qgd_files',0,null,null,null)
INSERT INTO [T_Instrument_Class] VALUES ('Thermo_Exactive',1,'dot_raw_files',0,'No longer used: HMS','<sections><section name="DatasetQC"><item key="SaveTICAndBPIPlots" value="True" /><item key="SaveLCMS2DPlots" value="True" /><item key="ComputeOverallQualityScores" value="True" /><item key="CreateDatasetInfoFile" value="True" /><item key="LCMS2DPlotMZResolution" value="0.4" /><item key="LCMS2DPlotMaxPointsToPlot" value="200000" /><item key="LCMS2DPlotMinPointsPerSpectrum" value="2" /><item key="LCMS2DPlotMinIntensity" value="0" /><item key="LCMS2DOverviewPlotDivisor" value="10" /></section></sections>',null)
INSERT INTO [T_Instrument_Class] VALUES ('Thermo_SII_LC',1,'dot_raw_files',0,null,'<sections><section name="DatasetQC"><item key="SaveTICAndBPIPlots" value="True" /><item key="CreateDatasetInfoFile" value="True" /></section></sections>','SII - Standard Instrument Integration, allows controlling Chromeleon-supported LC modules from Xcalibur')
INSERT INTO [T_Instrument_Class] VALUES ('Triple_Quad',1,'dot_raw_files',0,'No longer used: MS, MS-MSn, MRM','<sections><section name="DatasetQC"><item key="SaveTICAndBPIPlots" value="True" /><item key="SaveLCMS2DPlots" value="True" /><item key="ComputeOverallQualityScores" value="True" /><item key="CreateDatasetInfoFile" value="True" /><item key="LCMS2DPlotMZResolution" value="0.4" /><item key="LCMS2DPlotMaxPointsToPlot" value="200000" /><item key="LCMS2DPlotMinPointsPerSpectrum" value="2" /><item key="LCMS2DPlotMinIntensity" value="0" /><item key="LCMS2DOverviewPlotDivisor" value="10" /></section></sections>',null)
INSERT INTO [T_Instrument_Class] VALUES ('Waters_IMS',1,'dot_raw_folder',0,null,null,'Waters Synapt TWIMS')
INSERT INTO [T_Instrument_Class] VALUES ('Waters_TOF',0,'dot_raw_folder',0,null,'<sections><section name="DatasetQC"><item key="SaveTICAndBPIPlots" value="True" /><item key="SaveLCMS2DPlots" value="True" /><item key="ComputeOverallQualityScores" value="True" /><item key="CreateDatasetInfoFile" value="True" /><item key="LCMS2DPlotMZResolution" value="0.4" /><item key="LCMS2DPlotMaxPointsToPlot" value="200000" /><item key="LCMS2DPlotMinPointsPerSpectrum" value="2" /><item key="LCMS2DPlotMinIntensity" value="0" /><item key="LCMS2DOverviewPlotDivisor" value="10" /></section></sections>',null)
