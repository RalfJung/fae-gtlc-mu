From fae_gtlc_mu.refinements.static_gradual Require Export logical_relation resources_right compat_easy compat_cast.defs.
From fae_gtlc_mu.cast_calculus Require Export types typing.
From fae_gtlc_mu.cast_calculus Require Export lang.
From iris.algebra Require Import list.
From iris.proofmode Require Import tactics.
From iris.program_logic Require Import lifting.
From fae_gtlc_mu.backtranslation.cast_help Require Export general_def general_def_lemmas extract embed between_rec_fix.
From fae_gtlc_mu.cast_calculus Require Export lang types.

Section between_rec.
  Context `{!implG Σ,!specG Σ}.
  Notation D := (prodO stlc_mu.lang.valO cast_calculus.lang.valO -n> iPropO Σ).
  (* Implicit Types e : stlc_mu.lang.expr. *)
  Implicit Types fs : list stlc_mu.lang.val.
  (* Implicit Types f : stlc_mu.lang.val. *)
  Implicit Types A : list (cast_calculus.types.type * cast_calculus.types.type).
  (* Implicit Types a : (cast_calculus.types.type * cast_calculus.types.type). *)
  Local Hint Resolve to_of_val : core.

  (** Proving it *)

  Lemma back_cast_ar_trec_trec_use:
    ∀ (A : list (type * type)) (τl τr : {bind type}) (i : nat) (pμτlμtrinA : A !! i = Some (TRec τl, TRec τr)),
      back_cast_ar (atomic_UseRecursion A τl τr i pμτlμtrinA).
  Proof.
    intros A τl τr i pμτlμtr.
    rewrite /𝓕c /𝓕 /back_cast_ar; iIntros (ei' K' v v' fs) "(#Hfs & #Hvv' & #Hei' & Hv')".
    rewrite /𝓕c /𝓕. asimpl.
    (** getting the information about the length of the list *)
    iDestruct "Hfs" as "[% Hfs']".
    destruct (fs !! i) as [f | abs] eqn:Hf.
    rewrite (stlc_mu.typing_lemmas.env_subst_lookup _ i f); try done.
    {
      iDestruct (big_sepL2_lookup with "Hfs'") as "#Hf". exact pμτlμtr. exact Hf.
      iApply ("Hf" $! v v' with "Hvv'"). done.
    }
    { (* trivially impossible case *)
      assert (Hi : i < length fs). rewrite -H. by eapply lookup_lt_Some.
      assert (Hi' : i >= length fs). by apply lookup_ge_None_1. exfalso. lia.
    }
  Qed.

  Lemma back_cast_ar_trec_trec_expose:
    ∀ (A : list (type * type)) (τl τr : {bind type}) (pμτlμτrnotA : (TRec τl, TRec τr) ∉ A)
      (pC : alternative_consistency ((TRec τl, TRec τr) :: A) τl.[TRec τl/] τr.[TRec τr/]) (IHpC : back_cast_ar pC),
      back_cast_ar (exposeRecursiveCAll A τl τr pμτlμτrnotA pC).
  Proof.
    intros A τl τr pμτlμτrnotA pC IHpC.
    rewrite /𝓕c /𝓕 /back_cast_ar; iIntros (ei' K' v v' fs) "(#Hfs & #Hvv' & #Hei' & Hv')".
    (** setting up iLöb *)
    iLöb as "IHlob" forall (v v' ei' K') "Hvv' Hei'".
    (* fold (𝓕c (exposeRecursiveCAll A τl τr pμτlμτrnotA pC) fs). *)
    (* iRevert (ei' K' v v') "Hvv' Hei' Hv'". *)
    rewrite {2}/𝓕c. rewrite /𝓕.
    fold (𝓕 pC).
    (** rewriting value relation for v and v' *)
    (* rewrite fixpoint_interp_rec1_eq. *)
    rewrite interp_rw_TRec.
    iDestruct "Hvv'" as (w w') "#[% Hww']".
    inversion H; clear v v' H H1 H2.
    (** evaluation steps in WP *)
    iDestruct "Hfs" as "[% Hfs']"; iAssert (rel_cast_functions A fs) with "[Hfs']" as "Hfs". iSplit; done.
    iApply (wp_pure_step_later _ _ _ (stlc_mu.lang.Fold ((𝓕c pC (𝓕cV (exposeRecursiveCAll A τl τr pμτlμτrnotA pC) fs H :: fs)) w)) True); auto. intros _. apply between_TRec_steps.
    (** WP *)
    repeat iModIntro.
    iApply (wp_bind (stlc_mu.lang.fill_item $ stlc_mu.lang.FoldCtx)).
    (** eval specification side *)
    iMod (step_pure _ ei' K'
                    (Cast (Fold w') (TRec τl) (TRec τr))
                    (Fold (Cast w' (τl.[TRec τl/]) (τr.[TRec τr/]))) with "[Hv']") as "Hv'".
    intros. apply (RecursiveCast _ w'). rewrite -to_of_val. auto. auto. by iFrame.
    (** apply IH *)

    iApply (wp_wand with "[-]").
    iApply (IHpC ei' (FoldCtx :: K') w w' (𝓕cV (exposeRecursiveCAll A τl τr pμτlμτrnotA pC) fs H :: fs)). iSplitL "Hfs". iSplitR. simpl. by rewrite H.
    (** applying IHlob and Hfs *)
    (* rewrite /𝓕c. *)
    iSplit.
    iModIntro. iIntros (v v') "#Hvv'".
    { clear K'. iIntros (K') "Hv'". iSimpl in "Hv'".
      rewrite -𝓕c_rewrite.
      iApply ("IHlob" $! v v' with "Hv' Hvv' Hei'").
    }
    done. iSplitR. done. iSplitR. done. by simpl.
    (** finish *)
    iIntros (v) "H".
    iDestruct "H" as (v') "[Hv' #Hvv']".
    iApply wp_value.
    iExists (FoldV v').
    iFrame.
    rewrite interp_rw_TRec.
    simpl. iModIntro.
    iExists v , v'.
    iSplitR. done. auto.
  Qed.

End between_rec.
