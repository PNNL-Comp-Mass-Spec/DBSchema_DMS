/****** Object:  Table [dbo].[T_Aux_Info_Allowed_Values] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Aux_Info_Allowed_Values](
	[Aux_Description_ID] [int] NOT NULL,
	[Value] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_AuxInfo_Allowed_Values] PRIMARY KEY CLUSTERED 
(
	[Aux_Description_ID] ASC,
	[Value] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Aux_Info_Allowed_Values] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Aux_Info_Allowed_Values]  WITH CHECK ADD  CONSTRAINT [FK_T_AuxInfo_Allowed_Values_T_AuxInfo_Description] FOREIGN KEY([Aux_Description_ID])
REFERENCES [dbo].[T_Aux_Info_Description] ([Aux_Description_ID])
GO
ALTER TABLE [dbo].[T_Aux_Info_Allowed_Values] CHECK CONSTRAINT [FK_T_AuxInfo_Allowed_Values_T_AuxInfo_Description]
GO
