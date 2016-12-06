/****** Object:  Table [dbo].[T_Sample_Prep_Request_Items] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Sample_Prep_Request_Items](
	[ID] [int] NOT NULL,
	[Item_ID] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Item_Name] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Item_Type] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Status] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Created] [datetime] NULL,
	[Item_Added] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Sample_Prep_Request_Items] PRIMARY KEY CLUSTERED 
(
	[ID] ASC,
	[Item_ID] ASC,
	[Item_Type] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Sample_Prep_Request_Items] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request_Items] ADD  DEFAULT (getdate()) FOR [Item_Added]
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request_Items]  WITH CHECK ADD  CONSTRAINT [FK_T_Sample_Prep_Request_Items_T_Sample_Prep_Request] FOREIGN KEY([ID])
REFERENCES [dbo].[T_Sample_Prep_Request] ([ID])
GO
ALTER TABLE [dbo].[T_Sample_Prep_Request_Items] CHECK CONSTRAINT [FK_T_Sample_Prep_Request_Items_T_Sample_Prep_Request]
GO
