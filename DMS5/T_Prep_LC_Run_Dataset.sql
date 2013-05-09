/****** Object:  Table [dbo].[T_Prep_LC_Run_Dataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Prep_LC_Run_Dataset](
	[Prep_LC_Run_ID] [int] NOT NULL,
	[Dataset_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Prep_LC_Run_Dataset] PRIMARY KEY CLUSTERED 
(
	[Prep_LC_Run_ID] ASC,
	[Dataset_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Prep_LC_Run_Dataset]  WITH CHECK ADD  CONSTRAINT [FK_T_Prep_LC_Run_Dataset_T_Dataset] FOREIGN KEY([Dataset_ID])
REFERENCES [T_Dataset] ([Dataset_ID])
GO
ALTER TABLE [dbo].[T_Prep_LC_Run_Dataset] CHECK CONSTRAINT [FK_T_Prep_LC_Run_Dataset_T_Dataset]
GO
ALTER TABLE [dbo].[T_Prep_LC_Run_Dataset]  WITH CHECK ADD  CONSTRAINT [FK_T_Prep_LC_Run_Dataset_T_Prep_LC_Run] FOREIGN KEY([Prep_LC_Run_ID])
REFERENCES [T_Prep_LC_Run] ([ID])
GO
ALTER TABLE [dbo].[T_Prep_LC_Run_Dataset] CHECK CONSTRAINT [FK_T_Prep_LC_Run_Dataset_T_Prep_LC_Run]
GO
