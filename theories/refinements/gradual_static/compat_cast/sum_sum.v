From fae_gtlc_mu.refinements.gradual_static Require Export compat_cast.defs.
From fae_gtlc_mu.stlc_mu Require Export lang.
From fae_gtlc_mu.cast_calculus Require Export types.

Section compat_cast_sum_sum.
  Context `{!implG Σ,!specG Σ}.

  Hint Extern 5 (AsVal _) => eexists; simpl; try done; eapply cast_calculus.lang.of_to_val; fast_done : typeclass_instances.

  Lemma back_cast_ar_sum_sum:
    ∀ (A : list (type * type)) (τ1 τ1' τ2 τ2' : type) (pC1 : alternative_consistency A τ1 τ1') (pC2 : alternative_consistency A τ2 τ2')
      (IHpC1 : back_cast_ar pC1) (IHpC2 : back_cast_ar pC2),
      back_cast_ar (throughSum A τ1 τ1' τ2 τ2' pC1 pC2).
  Proof.
    intros A τ1 τ1' τ2 τ2' pC1 pC2 IHpC1 IHpC2.
    rewrite /back_cast_ar. iIntros (ei' K' v v' fs) "(#Hfs & #Hvv' & #Hei' & Hv')".
    iDestruct "Hfs" as "[% Hfs']"; iAssert (rel_cast_functions A fs) with "[Hfs']" as "Hfs". iSplit; done. iClear "Hfs'".
    rewrite /𝓕c /𝓕. fold (𝓕 pC1) (𝓕 pC2). rewrite between_TSum_subst_rewrite /between_TSum.
    iMod ((step_lam _ ei' K') with "[Hv']") as "Hv'"; auto. simpl.
    rewrite interp_rw_TSum.
    iDestruct "Hvv'" as "[H1 | H2]".
    + iDestruct "H1" as ((v1 , v1')) "[% Hv1v1']". inversion H0. clear H0 H2 H3 v v'.
      iMod ((step_case_inl _ ei' K') with "[Hv']") as "Hv'"; auto. asimpl.
      wp_head.
      iApply (wp_bind [cast_calculus.lang.InjLCtx]).
      iApply (wp_wand with "[-]").
      iApply (IHpC1 ei' (InjLCtx :: K') with "[Hv']"); iFrame; auto.
      iIntros (v1f) "HHH". iDestruct "HHH" as (v1f') "[Hv1f' Hv1fv1f']".
      iApply wp_value.
      iExists (InjLV v1f').
      iSplitL "Hv1f'". done.
      rewrite interp_rw_TSum.
      iLeft. iExists (v1f , v1f'). by iFrame.
    + iDestruct "H2" as ((v1 , v1')) "[% Hv1v1']". inversion H0. clear H0 H2 H3 v v'.
      iMod ((step_case_inr _ ei' K') with "[Hv']") as "Hv'"; auto. asimpl.
      wp_head.
      iApply (wp_bind [cast_calculus.lang.InjRCtx]).
      iApply (wp_wand with "[-]").
      iApply (IHpC2 ei' (InjRCtx :: K') with "[Hv']"); iFrame; auto.
      iIntros (v2f) "HHH". iDestruct "HHH" as (v2f') "[Hv2f' Hv2fv2f']".
      iApply wp_value.
      iExists (InjRV v2f').
      iSplitL "Hv2f'". done.
      rewrite interp_rw_TSum.
      iRight. iExists (v2f , v2f'). by iFrame.
  Qed.


End compat_cast_sum_sum.
