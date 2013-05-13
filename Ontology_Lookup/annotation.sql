/****** Object:  Table [dbo].[annotation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[annotation](
	[annotation_id] [int] NOT NULL,
	[term_pk] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[annotation_num_value] [float] NULL,
	[annotation_name] [varchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[annotation_str_value] [varchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_annotation] PRIMARY KEY CLUSTERED 
(
	[annotation_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
ALTER TABLE [dbo].[annotation]  WITH NOCHECK ADD  CONSTRAINT [FK_annotation_term] FOREIGN KEY([term_pk])
REFERENCES [term] ([term_pk])
GO
ALTER TABLE [dbo].[annotation] CHECK CONSTRAINT [FK_annotation_term]
GO
