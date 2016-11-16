/****** Object:  Table [dbo].[x_T_Protein_Aux_Info] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[x_T_Protein_Aux_Info](
	[Info_ID] [int] IDENTITY(1,1) NOT NULL,
	[Info_Type_ID] [int] NOT NULL,
	[Info_Value] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Protein_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Protein_Aux_Info] PRIMARY KEY CLUSTERED 
(
	[Info_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [IX_T_Protein_Aux_Info] UNIQUE NONCLUSTERED 
(
	[Info_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[x_T_Protein_Aux_Info]  WITH CHECK ADD  CONSTRAINT [FK_T_Protein_Aux_Info_T_Protein_Aux_Info_Types] FOREIGN KEY([Info_Type_ID])
REFERENCES [dbo].[x_T_Protein_Aux_Info_Types] ([Info_Type_ID])
GO
ALTER TABLE [dbo].[x_T_Protein_Aux_Info] CHECK CONSTRAINT [FK_T_Protein_Aux_Info_T_Protein_Aux_Info_Types]
GO
ALTER TABLE [dbo].[x_T_Protein_Aux_Info]  WITH CHECK ADD  CONSTRAINT [FK_T_Protein_Aux_Info_T_Proteins] FOREIGN KEY([Protein_ID])
REFERENCES [dbo].[T_Proteins] ([Protein_ID])
GO
ALTER TABLE [dbo].[x_T_Protein_Aux_Info] CHECK CONSTRAINT [FK_T_Protein_Aux_Info_T_Proteins]
GO
