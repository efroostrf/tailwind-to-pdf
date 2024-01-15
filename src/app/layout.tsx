import type { Metadata } from "next";
import { Roboto } from "next/font/google";
import { FC, PropsWithChildren } from "react";
import "./globals.css";

const roboto = Roboto({
  subsets: ["latin"],
  weight: ["400", "700", "900"],
});

export const metadata: Metadata = {
  title: "Next 14 Template",
  description: "Created by Yefrosynii",
};

const RootLayout: FC<PropsWithChildren> = (props) => {
  const { children } = props;

  return (
    <html lang="en">
      <body className={roboto.className}>{children}</body>
    </html>
  );
};

export default RootLayout;
