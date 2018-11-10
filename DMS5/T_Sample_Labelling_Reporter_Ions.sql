/****** Object:  Table [dbo].[T_Sample_Labelling_Reporter_Ions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Sample_Labelling_Reporter_Ions](
	[Label] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Channel] [tinyint] NOT NULL,
	[Tag_Name] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[MASIC_Name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Reporter_Ion_Mz] [float] NULL,
 CONSTRAINT [PK_T_Sample_Labelling_Reporter_Ions] PRIMARY KEY CLUSTERED 
(
	[Label] ASC,
	[Channel] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Sample_Labelling_Reporter_Ions]  WITH CHECK ADD  CONSTRAINT [FK_T_Sample_Labelling_Reporter_Ions_T_Sample_Labelling] FOREIGN KEY([Label])
REFERENCES [dbo].[T_Sample_Labelling] ([Label])
GO
ALTER TABLE [dbo].[T_Sample_Labelling_Reporter_Ions] CHECK CONSTRAINT [FK_T_Sample_Labelling_Reporter_Ions_T_Sample_Labelling]
GO
