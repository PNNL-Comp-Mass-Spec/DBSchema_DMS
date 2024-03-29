/****** Object:  Table [T_Protein_Collection_States] ******/
/****** RowCount: 6 ******/
/****** Columns: Collection_State_ID, State, Description ******/
INSERT INTO [T_Protein_Collection_States] VALUES (0,'Unknown','Protein collection does not exist')
INSERT INTO [T_Protein_Collection_States] VALUES (1,'New','Newly entered, in development')
INSERT INTO [T_Protein_Collection_States] VALUES (2,'Provisional','In Review before release to production')
INSERT INTO [T_Protein_Collection_States] VALUES (3,'Production','Currently in use for analyses')
INSERT INTO [T_Protein_Collection_States] VALUES (4,'Retired','No longer used for analyses, kept for legacy reasons')
INSERT INTO [T_Protein_Collection_States] VALUES (5,'Proteins_Deleted','Protein names, descriptions, and sequences are no longer in the database')
