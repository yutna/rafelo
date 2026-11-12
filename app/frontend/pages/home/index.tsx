import { Head } from "@inertiajs/react";

import { HomeScreen } from "../../screens/home/home_screen";

type HomeIndexProps = {
  message: string;
};

export default function HomeIndex({ message }: HomeIndexProps) {
  return (
    <>
      <Head title="Rafelo" />
      <HomeScreen message={message} />
    </>
  );
}
