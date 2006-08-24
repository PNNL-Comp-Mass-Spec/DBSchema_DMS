/****** Object:  Table [dbo].[T_LC_Cart_Version] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_LC_Cart_Version](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Cart_ID] [int] NOT NULL,
	[Effective_Date] [datetime] NULL,
	[Version] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Description] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Version_Number] [int] NOT NULL CONSTRAINT [DF_T_LC_Cart_Version_Version_Number]  DEFAULT (1),
 CONSTRAINT [PK_T_LC_Cart_Version] PRIMARY KEY NONCLUSTERED 
(
	[ID] ASC
) ON [PRIMARY],
 CONSTRAINT [IX_T_LC_Cart_Version_1] UNIQUE NONCLUSTERED 
(
	[Cart_ID] ASC,
	[Version_Number] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_LC_Cart_Version] ******/
CREATE CLUSTERED INDEX [IX_T_LC_Cart_Version] ON [dbo].[T_LC_Cart_Version] 
(
	[Cart_ID] ASC
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_LC_Cart_Version]  WITH CHECK ADD  CONSTRAINT [FK_T_LC_Cart_Version_T_LC_Cart] FOREIGN KEY([Cart_ID])
REFERENCES [T_LC_Cart] ([ID])
GO
