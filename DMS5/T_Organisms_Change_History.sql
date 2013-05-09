/****** Object:  Table [dbo].[T_Organisms_Change_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Organisms_Change_History](
	[Event_ID] [int] IDENTITY(1,1) NOT NULL,
	[Organism_ID] [int] NOT NULL,
	[OG_name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[OG_description] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Short_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Domain] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Kingdom] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Phylum] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Class] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Order] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Family] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Genus] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Species] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Strain] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[OG_Active] [tinyint] NULL,
	[Entered] [datetime] NOT NULL,
	[Entered_By] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Organisms_Change_History] PRIMARY KEY CLUSTERED 
(
	[Event_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Organisms_Change_History] ******/
CREATE NONCLUSTERED INDEX [IX_T_Organisms_Change_History] ON [dbo].[T_Organisms_Change_History] 
(
	[Organism_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
GO
GRANT INSERT ON [dbo].[T_Organisms_Change_History] TO [DMS_Limited_Organism_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Organisms_Change_History] TO [DMS_Limited_Organism_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[T_Organisms_Change_History] TO [DMS_Limited_Organism_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Organisms_Change_History] ([Entered_By]) TO [DMS2_SP_User] AS [dbo]
GO
ALTER TABLE [dbo].[T_Organisms_Change_History] ADD  CONSTRAINT [DF_T_Organisms_Change_History_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Organisms_Change_History] ADD  CONSTRAINT [DF_T_Organisms_Change_History_Entered_By]  DEFAULT (suser_sname()) FOR [Entered_By]
GO
