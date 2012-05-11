/****** Object:  Table [dbo].[T_AuxInfo_Allowed_Values] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_AuxInfo_Allowed_Values](
	[AuxInfoID] [int] NOT NULL,
	[Value] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_AuxInfo_Allowed_Values] PRIMARY KEY CLUSTERED 
(
	[AuxInfoID] ASC,
	[Value] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_AuxInfo_Allowed_Values]  WITH CHECK ADD  CONSTRAINT [FK_T_AuxInfo_Allowed_Values_T_AuxInfo_Description] FOREIGN KEY([AuxInfoID])
REFERENCES [T_AuxInfo_Description] ([ID])
GO
ALTER TABLE [dbo].[T_AuxInfo_Allowed_Values] CHECK CONSTRAINT [FK_T_AuxInfo_Allowed_Values_T_AuxInfo_Description]
GO
