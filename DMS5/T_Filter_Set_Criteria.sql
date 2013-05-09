/****** Object:  Table [dbo].[T_Filter_Set_Criteria] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Filter_Set_Criteria](
	[Filter_Set_Criteria_ID] [int] IDENTITY(1,1) NOT NULL,
	[Filter_Criteria_Group_ID] [int] NOT NULL,
	[Criterion_ID] [int] NOT NULL,
	[Criterion_Comparison] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Criterion_Value] [float] NOT NULL,
 CONSTRAINT [PK_T_Filter_Set_Criteria] PRIMARY KEY NONCLUSTERED 
(
	[Filter_Set_Criteria_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Filter_Set_Criteria_Group_ID_Criterion_ID] ******/
CREATE UNIQUE CLUSTERED INDEX [IX_T_Filter_Set_Criteria_Group_ID_Criterion_ID] ON [dbo].[T_Filter_Set_Criteria] 
(
	[Filter_Criteria_Group_ID] ASC,
	[Criterion_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Filter_Set_Criteria_Criterion_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Filter_Set_Criteria_Criterion_ID] ON [dbo].[T_Filter_Set_Criteria] 
(
	[Criterion_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
GRANT DELETE ON [dbo].[T_Filter_Set_Criteria] TO [Limited_Table_Write] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Filter_Set_Criteria] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Filter_Set_Criteria] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Filter_Set_Criteria] TO [Limited_Table_Write] AS [dbo]
GO
ALTER TABLE [dbo].[T_Filter_Set_Criteria]  WITH CHECK ADD  CONSTRAINT [FK_T_Filter_Set_Criteria_T_Filter_Set_Criteria_Groups] FOREIGN KEY([Filter_Criteria_Group_ID])
REFERENCES [T_Filter_Set_Criteria_Groups] ([Filter_Criteria_Group_ID])
GO
ALTER TABLE [dbo].[T_Filter_Set_Criteria] CHECK CONSTRAINT [FK_T_Filter_Set_Criteria_T_Filter_Set_Criteria_Groups]
GO
ALTER TABLE [dbo].[T_Filter_Set_Criteria]  WITH CHECK ADD  CONSTRAINT [FK_T_Filter_Set_Criteria_T_Filter_Set_Criteria_Names] FOREIGN KEY([Criterion_ID])
REFERENCES [T_Filter_Set_Criteria_Names] ([Criterion_ID])
GO
ALTER TABLE [dbo].[T_Filter_Set_Criteria] CHECK CONSTRAINT [FK_T_Filter_Set_Criteria_T_Filter_Set_Criteria_Names]
GO
ALTER TABLE [dbo].[T_Filter_Set_Criteria]  WITH CHECK ADD  CONSTRAINT [CK_T_Filter_Set_Criteria_Comparison] CHECK  (([Criterion_Comparison] = '>=' or ([Criterion_Comparison] = '<=' or ([Criterion_Comparison] = '>' or ([Criterion_Comparison] = '=' or [Criterion_Comparison] = '<')))))
GO
ALTER TABLE [dbo].[T_Filter_Set_Criteria] CHECK CONSTRAINT [CK_T_Filter_Set_Criteria_Comparison]
GO
