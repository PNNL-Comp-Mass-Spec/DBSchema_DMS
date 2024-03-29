/****** Object:  Table [dbo].[T_LC_Cart] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_LC_Cart](
	[ID] [int] IDENTITY(10,1) NOT NULL,
	[Cart_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Cart_State_ID] [int] NOT NULL,
	[Cart_Description] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Created] [smalldatetime] NULL,
 CONSTRAINT [PK_T_LC_Cart] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY],
 CONSTRAINT [IX_T_LC_Cart] UNIQUE NONCLUSTERED 
(
	[Cart_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_LC_Cart] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_LC_Cart] ADD  CONSTRAINT [DF_T_LC_Cart_Cart_State_ID]  DEFAULT (2) FOR [Cart_State_ID]
GO
ALTER TABLE [dbo].[T_LC_Cart] ADD  CONSTRAINT [DF_T_LC_Cart_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[T_LC_Cart]  WITH CHECK ADD  CONSTRAINT [FK_T_LC_Cart_T_LC_Cart_State] FOREIGN KEY([Cart_State_ID])
REFERENCES [dbo].[T_LC_Cart_State_Name] ([ID])
GO
ALTER TABLE [dbo].[T_LC_Cart] CHECK CONSTRAINT [FK_T_LC_Cart_T_LC_Cart_State]
GO
ALTER TABLE [dbo].[T_LC_Cart]  WITH CHECK ADD  CONSTRAINT [CK_T_LC_Cart_CartName_WhiteSpace] CHECK  (([dbo].[has_whitespace_chars]([Cart_Name],(0))=(0)))
GO
ALTER TABLE [dbo].[T_LC_Cart] CHECK CONSTRAINT [CK_T_LC_Cart_CartName_WhiteSpace]
GO
