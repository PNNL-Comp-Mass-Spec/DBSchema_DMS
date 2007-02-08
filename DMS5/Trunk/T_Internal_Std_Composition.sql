/****** Object:  Table [dbo].[T_Internal_Std_Composition] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Internal_Std_Composition](
	[Component_ID] [int] NOT NULL,
	[Mix_ID] [int] NOT NULL,
	[Concentration] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_T_Internal_Std_Composition_Concentration]  DEFAULT (''),
 CONSTRAINT [PK_T_Internal_Std_Composition] PRIMARY KEY CLUSTERED 
(
	[Mix_ID] ASC,
	[Component_ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Internal_Std_Composition]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Internal_Standards_Composition_T_Internal_Std_Components] FOREIGN KEY([Component_ID])
REFERENCES [T_Internal_Std_Components] ([Internal_Std_Component_ID])
GO
ALTER TABLE [dbo].[T_Internal_Std_Composition] CHECK CONSTRAINT [FK_T_Internal_Standards_Composition_T_Internal_Std_Components]
GO
ALTER TABLE [dbo].[T_Internal_Std_Composition]  WITH CHECK ADD  CONSTRAINT [FK_T_Internal_Std_Composition_T_Internal_Std_Parent_Mixes] FOREIGN KEY([Mix_ID])
REFERENCES [T_Internal_Std_Parent_Mixes] ([Parent_Mix_ID])
GO
ALTER TABLE [dbo].[T_Internal_Std_Composition] CHECK CONSTRAINT [FK_T_Internal_Std_Composition_T_Internal_Std_Parent_Mixes]
GO
