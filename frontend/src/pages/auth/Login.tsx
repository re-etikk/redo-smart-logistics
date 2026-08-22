const handleLoginSuccess = async () => {
  try {
    await refreshProfile();
    const { data } = await supabase.auth.getSession();
    const uid = data.session?.user.id;
    if (!uid) {
      setError("Session not found. Please try logging in again.");
      return;
    }
    const { data: prof, error: profErr } = await supabase
      .from("profiles")
      .select("role, onboarding_complete")
      .eq("id", uid)
      .single();

    if (profErr || !prof) {
      navigate("/signup");
    } else if (!prof.onboarding_complete) {
      navigate(prof.role === "sme" ? "/onboarding/sme" : "/onboarding/owner");
    } else {
      navigate(location.state?.from || (prof.role === "sme" ? "/dashboard/sme" : "/dashboard/owner"));
    }
  } catch (err: any) {
    setError(err?.message || "Something went wrong while loading your profile.");
  }
};

const submit = async (e: FormEvent) => {
  e.preventDefault();
  setBusy(true);
  setError("");
  try {
    const { error: err } = await supabase.auth.signInWithPassword({
      email: email.includes("@") ? email : `${email}@redo.app`,
      password,
    });
    if (err) throw err;
    await handleLoginSuccess();
  } catch (err: any) {
    setError(err?.message || "Login failed. Please check your credentials.");
  } finally {
    setBusy(false);
  }
};

const quickDemoLogin = async (role: "sme" | "truck_owner") => {
  setBusy(true);
  setError("");
  try {
    const result = await triggerDemoLogin(role);
    if (!result.success) {
      setError(result.error || "Demo login failed. Demo account may not be seeded yet.");
      return;
    }
    await handleLoginSuccess();
  } catch (err: any) {
    setError(err?.message || "Something went wrong.");
  } finally {
    setBusy(false);
  }
};
