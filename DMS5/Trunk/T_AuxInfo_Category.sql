/****** Object:  Table [dbo].[T_AuxInfo_Category] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_AuxInfo_Category](
	[ID] [int] IDENTITY(1000,1) NOT NULL,
	[Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Target_Type_ID] [int] NULL,
	[Sequence] [tinyint] NOT NULL CONSTRAINT [DF_T_AuxInfo_Category_Sequence]  DEFAULT (0),
 CONSTRAINT [PK_T_AuxInfo_Category] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_AuxInfo_Category]  WITH CHECK ADD  CONSTRAINT [FK_T_AuxInfo_Category_T_AuxInfo_Target] FOREIGN KEY([Target_Type_ID])
REFERENCES [T_AuxInfo_Target] ([ID])
GO
ALTER TABLE [dbo].[T_AuxInfo_Category] CHECK CONSTRAINT [FK_T_AuxInfo_Category_T_AuxInfo_Target]
GO
