/****** Object:  Table [dbo].[T_Organisms] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Organisms](
	[OG_name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Organism_ID] [int] IDENTITY(40,1) NOT NULL,
	[OG_organismDBPath] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_organismDBLocalPath] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_organismDBName] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_created] [datetime] NULL CONSTRAINT [DF_T_Organisms_OG_created]  DEFAULT (getdate()),
	[OG_description] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Short_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Storage_Location] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Domain] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Kingdom] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Phylum] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Class] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Order] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Family] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Genus] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Species] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Strain] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_DNA_Translation_Table_ID] [int] NULL,
	[OG_Mito_DNA_Translation_Table_ID] [int] NULL,
	[OG_Active] [tinyint] NULL CONSTRAINT [DF_T_Organisms_OG_Active]  DEFAULT (1),
 CONSTRAINT [PK_T_Organisms] PRIMARY KEY NONCLUSTERED 
(
	[Organism_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [IX_T_Organisms] UNIQUE NONCLUSTERED 
(
	[OG_name] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Organisms_OG_Created] ******/
CREATE NONCLUSTERED INDEX [IX_T_Organisms_OG_Created] ON [dbo].[T_Organisms] 
(
	[OG_created] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO

/****** Object:  Trigger [trig_i_T_Organisms] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create Trigger dbo.trig_i_T_Organisms on dbo.T_Organisms
For Insert
AS
	If @@RowCount = 0
		Return

	INSERT INTO T_Organisms_Change_History (
				Organism_ID, OG_name, OG_description, OG_Short_Name, 
				OG_Domain, OG_Kingdom, OG_Phylum, OG_Class, OG_Order, 
				OG_Family, OG_Genus, OG_Species, OG_Strain, OG_Active, 
				Entered, Entered_By)
	SELECT 	Organism_ID, OG_name, OG_description, OG_Short_Name, 
			OG_Domain, OG_Kingdom, OG_Phylum, OG_Class, OG_Order, 
			OG_Family, OG_Genus, OG_Species, OG_Strain, OG_Active, 
			GetDate(), SYSTEM_USER
	FROM inserted

GO

/****** Object:  Trigger [trig_u_T_Organisms] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create Trigger dbo.trig_u_T_Organisms on dbo.T_Organisms
For Update
AS
	If @@RowCount = 0
		Return

	if	update(OG_name) or 
		update(OG_Short_Name) or 
		update(OG_Domain) or
		update(OG_Kingdom) or
		update(OG_Phylum) or
		update(OG_Class) or
		update(OG_Order) or
		update(OG_Family) or
		update(OG_Genus) or
		update(OG_Species) or
		update(OG_Strain) or
		update(OG_Active)
		INSERT INTO T_Organisms_Change_History (
					Organism_ID, OG_name, OG_description, OG_Short_Name, 
					OG_Domain, OG_Kingdom, OG_Phylum, OG_Class, OG_Order, 
					OG_Family, OG_Genus, OG_Species, OG_Strain, OG_Active,
					Entered, Entered_By)
		SELECT 	inserted.Organism_ID, inserted.OG_name, inserted.OG_description, inserted.OG_Short_Name, 
				inserted.OG_Domain, inserted.OG_Kingdom, inserted.OG_Phylum, inserted.OG_Class, inserted.OG_Order, 
				inserted.OG_Family, inserted.OG_Genus, inserted.OG_Species, inserted.OG_Strain, inserted.OG_Active,
				GetDate(), SYSTEM_USER
		FROM deleted INNER JOIN inserted ON deleted.Organism_ID = inserted.Organism_ID

GO
GRANT INSERT ON [dbo].[T_Organisms] TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Organisms] TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Organisms] TO [Limited_Table_Write]
GO
