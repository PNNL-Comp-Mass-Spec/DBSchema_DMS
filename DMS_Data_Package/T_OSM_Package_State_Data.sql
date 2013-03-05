/****** Object:  Table [T_OSM_Package_State] ******/
/****** RowCount: 4 ******/
/****** Columns: Name, Description ******/
INSERT INTO [T_OSM_Package_State] VALUES ('Active','Package is currently being prepared')
INSERT INTO [T_OSM_Package_State] VALUES ('Complete','Package has been finalized; data has been sent to collaborator (if appropriate)')
INSERT INTO [T_OSM_Package_State] VALUES ('Future','Package has been created, but no data files have been added yet')
INSERT INTO [T_OSM_Package_State] VALUES ('Inactive','Package no longer contains useful data, or the data has been superseded')
