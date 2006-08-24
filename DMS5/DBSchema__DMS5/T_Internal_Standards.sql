/****** Object:  Table [dbo].[T_Internal_Standards] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Internal_Standards](
	[Internal_Std_Mix_ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Type] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Active] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Internal_Standards_Active]  DEFAULT ('A'),
 CONSTRAINT [PK_T_Internal_Standards] PRIMARY KEY CLUSTERED 
(
	[Internal_Std_Mix_ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Internal_Standards] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Internal_Standards] ON [dbo].[T_Internal_Standards] 
(
	[Name] ASC
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Internal_Standards]  WITH CHECK ADD  CONSTRAINT [CK_T_Internal_Standards] CHECK  (([Type] = 'All' or ([Type] = 'Postdigest' or [Type] = 'Predigest')))
GO
ALTER TABLE [dbo].[T_Internal_Standards]  WITH CHECK ADD  CONSTRAINT [CK_T_Internal_Standards_1] CHECK  (([Active] = 'A' or [Active] = 'I'))
GO
