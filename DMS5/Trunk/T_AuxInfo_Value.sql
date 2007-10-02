/****** Object:  Table [dbo].[T_AuxInfo_Value] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_AuxInfo_Value](
	[AuxInfo_ID] [int] NOT NULL,
	[Value] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Target_ID] [int] NOT NULL
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_AuxInfo_Value_Target_ID] ******/
CREATE CLUSTERED INDEX [IX_T_AuxInfo_Value_Target_ID] ON [dbo].[T_AuxInfo_Value] 
(
	[Target_ID] ASC,
	[AuxInfo_ID] ASC
) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_AuxInfo_Value_AuxInfo_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_AuxInfo_Value_AuxInfo_ID] ON [dbo].[T_AuxInfo_Value] 
(
	[AuxInfo_ID] ASC
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_AuxInfo_Value]  WITH NOCHECK ADD  CONSTRAINT [FK_T_AuxInfo_Value_T_AuxInfo_Description] FOREIGN KEY([AuxInfo_ID])
REFERENCES [T_AuxInfo_Description] ([ID])
GO
ALTER TABLE [dbo].[T_AuxInfo_Value] CHECK CONSTRAINT [FK_T_AuxInfo_Value_T_AuxInfo_Description]
GO
