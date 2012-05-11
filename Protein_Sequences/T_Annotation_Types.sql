/****** Object:  Table [dbo].[T_Annotation_Types] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Annotation_Types](
	[Annotation_Type_ID] [int] IDENTITY(1,1) NOT NULL,
	[TypeName] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Example] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Authority_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Annotation_Types] PRIMARY KEY CLUSTERED 
(
	[Annotation_Type_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Annotation_Types]  WITH CHECK ADD  CONSTRAINT [FK_T_Annotation_Types_T_Naming_Authorities] FOREIGN KEY([Authority_ID])
REFERENCES [T_Naming_Authorities] ([Authority_ID])
GO
ALTER TABLE [dbo].[T_Annotation_Types] CHECK CONSTRAINT [FK_T_Annotation_Types_T_Naming_Authorities]
GO
