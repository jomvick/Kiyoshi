import type { Metadata } from "next";
import { Montserrat, Inter, JetBrains_Mono } from "next/font/google";
import "./globals.css";

const montserrat = Montserrat({
  subsets: ["latin"],
  variable: "--font-montserrat",
  weight: ["300", "500", "600", "700"],
});

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
});

const jetbrains = JetBrains_Mono({
  subsets: ["latin"],
  variable: "--font-jetbrains",
  weight: ["500", "600", "700"],
});

export const metadata: Metadata = {
  title: "Kiyoshi — A quiet desktop for your work",
  description:
    "Notes, tasks, projects, and a calendar in one calm, glass-clear desktop workspace. Free and open source for Linux, macOS, and Windows.",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body
        className={`${montserrat.variable} ${inter.variable} ${jetbrains.variable} font-body antialiased`}
      >
        {children}
      </body>
    </html>
  );
}
