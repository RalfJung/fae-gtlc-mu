From fae_gtlc_mu.embedding Require Import types.

Lemma etype_ren_gen τ :
  forall k l, [| τ.[upn l (ren (+k))] |] = [|τ|].[upn l (ren (+k))].
Proof.
  induction τ; intros k l; try by asimpl.
  - asimpl. by rewrite IHτ1 IHτ2.
  - asimpl. by rewrite IHτ1 IHτ2.
  - asimpl. by rewrite IHτ1 IHτ2.
  - simpl. specialize (IHτ k (S l)). by rewrite IHτ.
  - asimpl. do 2 rewrite (iter_up l x (ren (+k))).
    destruct (lt_dec x l); by asimpl.
Qed.

Lemma embd_unfold_comm_gen (τb : stlc_mu.types.type) : forall (τ : stlc_mu.types.type) k,
  [| τb.[upn k (τ .: ids)] |] = [|τb|].[upn k ([|τ|] .: ids)].
Proof.
  induction τb; intros τ' k; try by asimpl.
  - asimpl. by rewrite IHτb1 IHτb2.
  - asimpl. by rewrite IHτb1 IHτb2.
  - asimpl. by rewrite IHτb1 IHτb2.
  - simpl. specialize (IHτb τ' (S k)). by rewrite IHτb.
  - asimpl.
    rewrite (iter_up k x (τ' .: ids)) (iter_up k x ([|τ'|] .: ids)).
    destruct (lt_dec x k).
      + by asimpl.
      + destruct (decide (x - k = 0)); asimpl. rewrite e. asimpl.
        cut ([| τ'.[upn 0 (ren (+k))] |] = ([| τ' |]).[upn 0 (ren (+k))]).
        by asimpl. by rewrite etype_ren_gen.
        destruct (x - k). exfalso; lia. by asimpl.
Qed.

Lemma embd_unfold_comm (τb : stlc_mu.types.type) :
  [| τb.[stlc_mu.types.TRec τb/]|] = [|τb|].[TRec [|τb|]/].
Proof.
  cut ([| (τb.[upn 0 ((stlc_mu.types.TRec τb) .: ids)])|] = [|τb|].[upn 0 ([|(stlc_mu.types.TRec τb)|] .: ids)]).
  by asimpl. apply embd_unfold_comm_gen.
Qed.

From fae_gtlc_mu.cast_calculus Require types_lemmas.
From fae_gtlc_mu.stlc_mu Require Import types_lemmas.

Lemma embd_closed_gen τ : forall n (pnτ : NClosed n τ), NClosed n [|τ|].
Proof.
  induction τ; intros n pnτ; simpl; try by (intro σ; by asimpl).
  - specialize (IHτ1 n (TProd_nclosed1 pnτ)).
    specialize (IHτ2 n (TProd_nclosed2 pnτ)).
    intro σ; asimpl; by rewrite IHτ1 IHτ2.
  - specialize (IHτ1 n (TSum_nclosed1 pnτ)).
    specialize (IHτ2 n (TSum_nclosed2 pnτ)).
    intro σ; asimpl; by rewrite IHτ1 IHτ2.
  - specialize (IHτ1 n (TArrow_nclosed1 pnτ)).
    specialize (IHτ2 n (TArrow_nclosed2 pnτ)).
    intro σ; asimpl; by rewrite IHτ1 IHτ2.
  - specialize (IHτ (S n) (TRec_nclosed1 pnτ)).
    intro σ; asimpl; by rewrite IHτ.
  - apply cast_calculus.types_lemmas.NClosed_var.
    by apply NClosed_var.
Qed.

Lemma embd_closed {τ : stlc_mu.types.type} (pτ : Closed τ) : Closed [|τ|].
Proof. apply (embd_closed_gen τ 0 pτ). Qed.
