/****** Object:  Table [dbo].[T_MaxQuant_Mods] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_MaxQuant_Mods](
	[Mod_ID] [int] IDENTITY(1,1) NOT NULL,
	[Mod_Title] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Mod_Position] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Mass_Correction_ID] [int] NULL,
	[Composition] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Isobaric_Mod_Ion_Number] [smallint] NOT NULL,
 CONSTRAINT [PK_T_MaxQuant_Mods] PRIMARY KEY CLUSTERED 
(
	[Mod_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_MaxQuant_Mods] ADD  CONSTRAINT [DF_T_MaxQuant_Mods_Mod_Position]  DEFAULT ('anywhere') FOR [Mod_Position]
GO
ALTER TABLE [dbo].[T_MaxQuant_Mods] ADD  CONSTRAINT [DF_T_MaxQuant_Mods_Isobaric_Mod_Ion_Number]  DEFAULT ((0)) FOR [Isobaric_Mod_Ion_Number]
GO
ALTER TABLE [dbo].[T_MaxQuant_Mods]  WITH CHECK ADD  CONSTRAINT [FK_T_MaxQuant_Mods_T_Mass_Correction_Factors] FOREIGN KEY([Mass_Correction_ID])
REFERENCES [dbo].[T_Mass_Correction_Factors] ([Mass_Correction_ID])
GO
ALTER TABLE [dbo].[T_MaxQuant_Mods] CHECK CONSTRAINT [FK_T_MaxQuant_Mods_T_Mass_Correction_Factors]
GO
