/****** Object:  Table [dbo].[T_AuxInfo_Value] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_AuxInfo_Value](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Aux_Description_ID] [int] NOT NULL,
	[Value] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Target_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_AuxInfo_Value] PRIMARY KEY NONCLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_AuxInfo_Value] TO [DDL_Viewer] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_AuxInfo_Value] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_AuxInfo_Value] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_AuxInfo_Value] TO [Limited_Table_Write] AS [dbo]
GO
/****** Object:  Index [IX_T_AuxInfo_Value_Target_ID] ******/
CREATE CLUSTERED INDEX [IX_T_AuxInfo_Value_Target_ID] ON [dbo].[T_AuxInfo_Value]
(
	[Target_ID] ASC,
	[Aux_Description_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_AuxInfo_Value_uniq_Aux_Description_ID_Target_ID] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_AuxInfo_Value_uniq_Aux_Description_ID_Target_ID] ON [dbo].[T_AuxInfo_Value]
(
	[Aux_Description_ID] ASC,
	[Target_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_AuxInfo_Value]  WITH CHECK ADD  CONSTRAINT [FK_T_AuxInfo_Value_T_AuxInfo_Description] FOREIGN KEY([Aux_Description_ID])
REFERENCES [dbo].[T_AuxInfo_Description] ([ID])
GO
ALTER TABLE [dbo].[T_AuxInfo_Value] CHECK CONSTRAINT [FK_T_AuxInfo_Value_T_AuxInfo_Description]
GO
