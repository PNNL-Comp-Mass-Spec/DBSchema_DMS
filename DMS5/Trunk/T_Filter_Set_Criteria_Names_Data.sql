/****** Object:  Table [T_Filter_Set_Criteria_Names] ******/
/****** RowCount: 17 ******/
SET IDENTITY_INSERT [T_Filter_Set_Criteria_Names] ON
INSERT INTO [T_Filter_Set_Criteria_Names] (Criterion_ID, Criterion_Name, Criterion_Description) VALUES (1,'Spectrum_Count','Number of distinct spectra the peptide is observed in, taking into account datasets analyzed multiple times')
INSERT INTO [T_Filter_Set_Criteria_Names] (Criterion_ID, Criterion_Name, Criterion_Description) VALUES (2,'Charge','Peptide charge')
INSERT INTO [T_Filter_Set_Criteria_Names] (Criterion_ID, Criterion_Name, Criterion_Description) VALUES (3,'High_Normalized_Score','Highest normalized score (e.g. XCorr for Sequest) observed')
INSERT INTO [T_Filter_Set_Criteria_Names] (Criterion_ID, Criterion_Name, Criterion_Description) VALUES (4,'Cleavage_State','For trypsin, 2=fully tryptic, 1=partially tryptic, 0=non tryptic')
INSERT INTO [T_Filter_Set_Criteria_Names] (Criterion_ID, Criterion_Name, Criterion_Description) VALUES (5,'Peptide_Length','Number of residues in the peptide')
INSERT INTO [T_Filter_Set_Criteria_Names] (Criterion_ID, Criterion_Name, Criterion_Description) VALUES (6,'Mass','Peptide mass')
INSERT INTO [T_Filter_Set_Criteria_Names] (Criterion_ID, Criterion_Name, Criterion_Description) VALUES (7,'DelCn','DeltaCn value, the normalized difference between the given peptide''s XCorr and the highest scoring peptide''s XCorr')
INSERT INTO [T_Filter_Set_Criteria_Names] (Criterion_ID, Criterion_Name, Criterion_Description) VALUES (8,'DelCn2','DeltaCn2 value, the normalized difference between the given peptide''s XCorr and the next lower scoring peptide''s XCorr')
INSERT INTO [T_Filter_Set_Criteria_Names] (Criterion_ID, Criterion_Name, Criterion_Description) VALUES (9,'Discriminant_Score','Sequest-based discriminant score')
INSERT INTO [T_Filter_Set_Criteria_Names] (Criterion_ID, Criterion_Name, Criterion_Description) VALUES (10,'NET_Difference_Absolute','Absolute value of the difference between observed normalized elution time (NET) and predicted NET')
INSERT INTO [T_Filter_Set_Criteria_Names] (Criterion_ID, Criterion_Name, Criterion_Description) VALUES (11,'Discriminant_Initial_Filter','Filter based on Xcorr, DelCN, RankXc and the number of tryptic termini (PassFilt column in synopsis and fht files)')
INSERT INTO [T_Filter_Set_Criteria_Names] (Criterion_ID, Criterion_Name, Criterion_Description) VALUES (12,'Protein_Count','Count of the number of proteins that a given peptide sequence is found in')
INSERT INTO [T_Filter_Set_Criteria_Names] (Criterion_ID, Criterion_Name, Criterion_Description) VALUES (13,'Terminus_State','Non-zero if peptide is at terminus of protein; 1=N-terminus, 2=C-terminus, 3=N and C-terminus')
INSERT INTO [T_Filter_Set_Criteria_Names] (Criterion_ID, Criterion_Name, Criterion_Description) VALUES (14,'XTandem_Hyperscore','XTandem Hyperscore')
INSERT INTO [T_Filter_Set_Criteria_Names] (Criterion_ID, Criterion_Name, Criterion_Description) VALUES (15,'XTandem_LogEValue','XTandem E-Value (base-10 log)')
INSERT INTO [T_Filter_Set_Criteria_Names] (Criterion_ID, Criterion_Name, Criterion_Description) VALUES (16,'Peptide_Prophet_Probability','Sequest-based probability developed by Andrew Keller')
INSERT INTO [T_Filter_Set_Criteria_Names] (Criterion_ID, Criterion_Name, Criterion_Description) VALUES (17,'RankScore','The rank of the given peptides score within the given scan; for Sequest, this is RankXc')
SET IDENTITY_INSERT [T_Filter_Set_Criteria_Names] OFF
