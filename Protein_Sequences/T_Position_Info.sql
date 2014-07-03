/****** Object:  Table [dbo].[T_Position_Info] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Position_Info](
	[Position_ID] [int] IDENTITY(1,1) NOT NULL,
	[Protein_ID] [int] NULL,
	[Start_Coordinate] [int] NULL,
	[End_Coordinate] [int] NULL,
	[Reading_Frame_Type_ID] [tinyint] NULL,
	[DNA_Structure_ID] [int] NULL,
 CONSTRAINT [PK_T_Position_Info] PRIMARY KEY CLUSTERED 
(
	[Position_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Position_Info]  WITH CHECK ADD  CONSTRAINT [FK_T_Position_Info_T_DNA_Structures] FOREIGN KEY([DNA_Structure_ID])
REFERENCES [dbo].[T_DNA_Structures] ([DNA_Structure_ID])
GO
ALTER TABLE [dbo].[T_Position_Info] CHECK CONSTRAINT [FK_T_Position_Info_T_DNA_Structures]
GO
ALTER TABLE [dbo].[T_Position_Info]  WITH CHECK ADD  CONSTRAINT [FK_T_Position_Info_T_Proteins] FOREIGN KEY([Protein_ID])
REFERENCES [dbo].[T_Proteins] ([Protein_ID])
GO
ALTER TABLE [dbo].[T_Position_Info] CHECK CONSTRAINT [FK_T_Position_Info_T_Proteins]
GO
ALTER TABLE [dbo].[T_Position_Info]  WITH CHECK ADD  CONSTRAINT [FK_T_Position_Info_T_Reading_Frame_Types] FOREIGN KEY([Reading_Frame_Type_ID])
REFERENCES [dbo].[T_Reading_Frame_Types] ([Reading_Frame_Type_ID])
GO
ALTER TABLE [dbo].[T_Position_Info] CHECK CONSTRAINT [FK_T_Position_Info_T_Reading_Frame_Types]
GO
