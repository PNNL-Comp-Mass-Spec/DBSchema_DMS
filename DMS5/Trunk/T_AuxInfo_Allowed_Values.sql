/****** Object:  Table [dbo].[T_AuxInfo_Allowed_Values] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_AuxInfo_Allowed_Values](
	[AuxInfoID] [int] NOT NULL,
	[Value] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_AuxInfo_Allowed_Values]  WITH CHECK ADD  CONSTRAINT [FK_T_AuxInfo_Allowed_Values_T_AuxInfo_Description] FOREIGN KEY([AuxInfoID])
REFERENCES [T_AuxInfo_Description] ([ID])
GO
