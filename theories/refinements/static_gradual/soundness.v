From iris.algebra Require Import excl auth frac agree.
From iris.proofmode Require Import tactics.
From iris.program_logic Require Import adequacy.
From iris.algebra Require Import agree.

From fae_gtlc_mu.refinements.static_gradual Require Export rel_ref_specs.
From fae_gtlc_mu.embedding Require Import types expressions.
From fae_gtlc_mu.backtranslation Require Import contexts.


Section soundness.
  Context `{!inG Σ specR, !invPreG Σ}.

  Lemma soundness
    (e : stlc_mu.lang.expr) (e' : cast_calculus.lang.expr) (τ : cast_calculus.types.type) (v : stlc_mu.lang.val) :
    (∀ `{!implG Σ, !specG Σ}, [] ⊨ e ≤log≤ e' : τ) →
    rtc (@erased_step stlc_mu.lang.lang) ([e], tt) (stlc_mu.lang.of_val v :: [], tt) →
    (∃ v', rtc (@erased_step cast_calculus.lang.lang) ([e'], tt) (of_val v' :: [], tt)).
  Proof.
    intros Hlog Hsteps.
    cut (adequate NotStuck e tt (λ _ _, ∃ v', rtc erased_step ([e'], tt) (of_val v' :: [], tt))).
    { destruct 1; naive_solver. }
    eapply (wp_adequacy Σ); first by apply _.
    iIntros (Hinv ?).
    iMod (own_alloc ((((1/2)%Qp , to_agree e') ⋅ ((1/2)%Qp , to_agree e')) : specR)) as (spec_name) "[Hs1 Hs2]".
    { rewrite -pair_op frac_op' Qp_half_half agree_idemp.
      apply pair_valid; split; try done; try by apply frac_valid'. }
    set (SpecΣ := SpecG Σ inG0 spec_name).
    set (ImplΣ := ImplG Σ Hinv).
    iMod (inv_alloc specN _ (initially_body e') with "[Hs1]") as "#Hinitially".
    { iNext. iExists e'. iSplit; eauto. }
    iExists (λ _ _, True%I), (λ _, True%I); iSplitR; first done.
    iApply wp_fupd. iApply (wp_wand with "[-]").
    - iPoseProof (Hlog ImplΣ SpecΣ [] [] e' with "[]") as "Hrel".
      { iSplit; auto. iApply interp_env_nil. }
      replace e with (e.[stlc_mu.typing.env_subst [] ]) at 2 by by asimpl.
      iApply ("Hrel" $! []). asimpl; iFrame.
    - iModIntro. simpl. iIntros (v'). iDestruct 1 as (v2) "[Hj #Hinterp]".
      iExists v2.
      iInv specN as ">Hinv" "Hclose".
      iDestruct "Hinv" as (e'') "[He'' %]".
      iDestruct (own_valid_2 with "He'' Hj") as %Hvalid.
      rewrite -pair_op frac_op' Qp_half_half in Hvalid.
      move: Hvalid=> /pair_valid [_ /agree_op_inv' b]. apply leibniz_equiv in b. subst.
      iMod ("Hclose" with "[-]") as "_".
      + iExists (#v2). auto.
      + iIntros "!> !%". eauto.
  Qed.

End soundness.
