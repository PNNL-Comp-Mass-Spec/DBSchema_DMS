/****** Object:  Table [T_Protein_Collection_States] ******/
/****** RowCount: 7 ******/
/****** Columns: Collection_State_ID, State, Description ******/
INSERT INTO [T_Protein_Collection_States] VALUES (0,'Unknown','protein collection does not exist')
INSERT INTO [T_Protein_Collection_States] VALUES (1,'New','not yet used by any analysis jobs')
INSERT INTO [T_Protein_Collection_States] VALUES (2,'Provisional','in review before release to production')
INSERT INTO [T_Protein_Collection_States] VALUES (3,'Production','currently in use by analysis jobs')
INSERT INTO [T_Protein_Collection_States] VALUES (4,'Retired','no longer used for analyses; kept for legacy reasons')
INSERT INTO [T_Protein_Collection_States] VALUES (5,'Proteins_Deleted','protein names, descriptions, and sequences have been deleted from the database, and we do not have the corresponding FASTA file')
INSERT INTO [T_Protein_Collection_States] VALUES (6,'Offline','protein names and sequences are no longer in the database; contact an admin to restore this protein collection using the FASTA file')
