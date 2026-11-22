import { SignInContainer } from "@/containers/sessions/sign_in_container";

type SignInScreenProps = {
  signInHref: string;
  error: string | null;
};

export function SignInScreen({ signInHref, error }: SignInScreenProps) {
  return <SignInContainer signInHref={signInHref} error={error} />;
}
