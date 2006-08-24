/****** Object:  Table [dbo].[T_AuxInfo_Value] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_AuxInfo_Value](
	[AuxInfo_ID] [int] NULL,
	[Value] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Target_ID] [int] NULL
) ON [PRIMARY]

GO

/****** Object:  Index [T_AuxInfo_Value1] ******/
CREATE CLUSTERED INDEX [T_AuxInfo_Value1] ON [dbo].[T_AuxInfo_Value] 
(
	[AuxInfo_ID] ASC
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_AuxInfo_Value]  WITH CHECK ADD  CONSTRAINT [FK_T_AuxInfo_Value_T_AuxInfo_Description] FOREIGN KEY([AuxInfo_ID])
REFERENCES [T_AuxInfo_Description] ([ID])
GO
